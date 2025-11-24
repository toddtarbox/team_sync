const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// When a database document's publicShareId is set/changed/removed, keep a
// top-level mapping under /shared_databases/<publicId> => { databasePath }
// This makes public lookups efficient while preserving per-db storage.

exports.onDatabasePublicShareIdChange = functions.database
  .ref('/subscriptionIds/{uid}/databases/{dbKey}/publicShareId')
  .onWrite(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const uid = context.params.uid;
    const dbKey = context.params.dbKey;
    const databasePath = `subscriptionIds/${uid}/databases/${dbKey}`;

    const db = admin.database();

    // If value removed, delete mapping for the previous id
    if (before && before !== after) {
      try {
        await db.ref(`shared_databases/${before}`).remove();
      } catch (e) {
        console.error('Failed to remove old mapping', before, e);
      }
    }

    // If new value set, create mapping
    if (after) {
      try {
        await db.ref(`shared_databases/${after}`).set({ databasePath });
      } catch (e) {
        console.error('Failed to set mapping for', after, e);
      }
    }

    return null;
  });

// When any row under a database's tables is written, update the database
// document's `lastUpdated` with a server timestamp. This allows read-only
// web viewers to show an authoritative last-updated time.
exports.onDatabaseRowWrite = functions.database
  .ref('/subscriptionIds/{uid}/databases/{dbKey}/{table}/{id}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const dbKey = context.params.dbKey;
    const databasePath = `subscriptionIds/${uid}/databases/${dbKey}`;

    const db = admin.database();
    const parentRef = db.ref(databasePath);

    try {
      await parentRef.update({ lastUpdated: admin.database.ServerValue.TIMESTAMP });
    } catch (e) {
      console.error('Failed to write lastUpdated for', databasePath, e);
    }

    return null;
  });

// HTTP callable function to update player profile with PIN authentication
// This allows unauthenticated web users to update their own profiles
exports.updatePlayerWithPin = functions.https.onCall(async (data, context) => {
  const { databasePath, playerId, seasonId, pin, updates, table, operation } = data;

  // Validate required fields
  if (!databasePath || !playerId || !seasonId || !pin) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: databasePath, playerId, seasonId, pin'
    );
  }

  // Default to Players table if not specified
  const targetTable = table || 'Players';

  // Validate table is allowed
  const allowedTables = ['Players', 'PlayerAwards', 'PlayerHighlights'];
  if (!allowedTables.includes(targetTable)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid table: ${targetTable}. Allowed tables: ${allowedTables.join(', ')}`
    );
  }

  const db = admin.database();

  try {
    // Find the player record to validate PIN
    const playersRef = db.ref(`${databasePath}/Players`);
    const snapshot = await playersRef.orderByChild('id').equalTo(playerId).once('value');

    if (!snapshot.exists()) {
      throw new functions.https.HttpsError('not-found', 'Player not found');
    }

    // Find the specific player for this season
    let playerData = null;

    snapshot.forEach((child) => {
      const data = child.val();
      if (data.seasonId === seasonId) {
        playerData = data;
        return true; // stop iteration
      }
    });

    if (!playerData) {
      throw new functions.https.HttpsError('not-found', 'Player not found for this season');
    }

    // Validate PIN (compare as strings to handle type mismatches)
    const storedPin = String(playerData.editPin || '');
    const providedPin = String(pin || '');

    if (storedPin !== providedPin) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid PIN');
    }

    // PIN is valid - now handle the specific table operation
    if (targetTable === 'Players' && updates) {
      // Original player profile update logic
      const playerKey = await findPlayerKey(db, databasePath, playerId, seasonId);

      // Whitelist allowed fields for Players table
      const allowedFields = ['profileImage', 'actionPhoto', 'firstName', 'lastName', 'number'];
      const sanitizedUpdates = {};

      for (const field of allowedFields) {
        if (updates.hasOwnProperty(field)) {
          sanitizedUpdates[field] = updates[field];
        }
      }

      // Prevent removal of PIN
      if (sanitizedUpdates.hasOwnProperty('editPin') && !sanitizedUpdates.editPin) {
        throw new functions.https.HttpsError('invalid-argument', 'Cannot remove PIN');
      }

      await db.ref(`${databasePath}/Players/${playerKey}`).update(sanitizedUpdates);

      return { success: true, message: 'Player profile updated successfully' };

    } else if (targetTable === 'PlayerAwards') {
      // Handle PlayerAwards - insert, update, or delete
      const { id, title, description, imageUrl } = updates || {};

      if (!id) {
        throw new functions.https.HttpsError('invalid-argument', 'Award requires id');
      }

      // Handle delete operation
      if (operation === 'delete') {
        await db.ref(`${databasePath}/PlayerAwards/${id}`).remove();
        return { success: true, message: 'Player award deleted successfully' };
      }

      // Handle save operation (insert or update)
      if (!title) {
        throw new functions.https.HttpsError('invalid-argument', 'Award requires title');
      }

      const awardData = {
        id,
        playerId,
        seasonId,
        title,
        description: description || null,
        imageUrl: imageUrl || null,
      };

      // Use the award ID as the key
      await db.ref(`${databasePath}/PlayerAwards/${id}`).set(awardData);

      return { success: true, message: 'Player award saved successfully' };

    } else if (targetTable === 'PlayerHighlights') {
      // Handle PlayerHighlights - insert or update
      const { id, title, description, videoUrl, date } = updates || {};

      if (!id || !title || !videoUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'Highlight requires id, title, and videoUrl');
      }

      const highlightData = {
        id,
        playerId,
        title,
        description: description || null,
        videoUrl,
        date: date || Date.now(),
      };

      // Use the highlight ID as the key
      await db.ref(`${databasePath}/PlayerHighlights/${id}`).set(highlightData);

      return { success: true, message: 'Player highlight saved successfully' };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid operation');

  } catch (error) {
    console.error('Error updating with PIN:', error);

    // Re-throw HttpsError
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update',
      error.message
    );
  }
});

// Helper function to find player key
async function findPlayerKey(db, databasePath, playerId, seasonId) {
  const playersRef = db.ref(`${databasePath}/Players`);
  const snapshot = await playersRef.orderByChild('id').equalTo(playerId).once('value');

  let playerKey = null;
  snapshot.forEach((child) => {
    const data = child.val();
    if (data.seasonId === seasonId) {
      playerKey = child.key;
      return true;
    }
  });

  if (!playerKey) {
    throw new functions.https.HttpsError('not-found', 'Player key not found');
  }

  return playerKey;
}

// Helper function to generate a new 4-digit PIN
function generateNewPin() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// HTTP callable function to regenerate PIN when user exits edit mode
// This ensures PIN is single-session only
exports.regeneratePlayerPin = functions.https.onCall(async (data, context) => {
  const { databasePath, playerId, seasonId, currentPin } = data;

  // Validate required fields
  if (!databasePath || !playerId || !seasonId || !currentPin) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: databasePath, playerId, seasonId, currentPin'
    );
  }

  const db = admin.database();

  try {
    // Find the player record to validate current PIN
    const playersRef = db.ref(`${databasePath}/Players`);
    const snapshot = await playersRef.orderByChild('id').equalTo(playerId).once('value');

    if (!snapshot.exists()) {
      throw new functions.https.HttpsError('not-found', 'Player not found');
    }

    // Find the specific player for this season
    let playerData = null;
    let playerKey = null;

    snapshot.forEach((child) => {
      const data = child.val();
      if (data.seasonId === seasonId) {
        playerData = data;
        playerKey = child.key;
        return true; // stop iteration
      }
    });

    if (!playerData || !playerKey) {
      throw new functions.https.HttpsError('not-found', 'Player not found for this season');
    }

    // Validate current PIN (compare as strings to handle type mismatches)
    const storedPin = String(playerData.editPin || '');
    const providedPin = String(currentPin || '');

    if (storedPin !== providedPin) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid PIN');
    }

    // Generate new PIN
    const newPin = generateNewPin();

    // Update the PIN in the database
    await db.ref(`${databasePath}/Players/${playerKey}`).update({ editPin: newPin });

    console.log(`PIN regenerated for player ${playerId}. New PIN: ${newPin}`);

    return { success: true, newPin: newPin };

  } catch (error) {
    console.error('Error regenerating PIN:', error);

    // Re-throw HttpsError
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new functions.https.HttpsError(
      'internal',
      'Failed to regenerate PIN',
      error.message
    );
  }
});
