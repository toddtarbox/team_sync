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
