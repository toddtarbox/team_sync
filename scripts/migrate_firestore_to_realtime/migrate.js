'use strict';

/**
 * Simple admin migration script: Firestore -> Realtime Database
 * Usage:
 *   node migrate.js --serviceAccount <path/to/key.json> --firestoreDocPath "databases/myDb" --rtBasePath "subscriptionIds/<uid>/databases/myDb" [--dry-run] [--yes] [--no-backup]
 *
 * Notes:
 * - This script uses the Firebase Admin SDK and requires a service account JSON key.
 * - It migrates the known tables: Teams, Seasons, Players, Games, Events (configurable below).
 * - It preserves Firestore document IDs as keys in Realtime Database.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

function printUsageAndExit() {
  console.log('Usage: node migrate.js --serviceAccount <key.json> --firestoreDocPath <path> --rtBasePath <path> [--dry-run] [--yes] [--no-backup] [--tables t1,t2]');
  process.exit(1);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--serviceAccount') out.serviceAccount = args[++i];
    else if (a === '--firestoreDocPath') out.firestoreDocPath = args[++i];
    else if (a === '--rtBasePath') out.rtBasePath = args[++i];
    else if (a === '--dry-run') out.dryRun = true;
    else if (a === '--tables') out.tables = args[++i];
    else if (a === '--yes') out.yes = true;
    else if (a === '--no-backup') out.noBackup = true;
    else if (a === '--help') printUsageAndExit();
    else {
      console.log('Unknown arg', a);
      printUsageAndExit();
    }
  }
  return out;
}

function firestoreValueToJson(v) {
  if (v === null || v === undefined) return null;
  if (Array.isArray(v)) return v.map(firestoreValueToJson);
  // Admin SDK Timestamp has toDate() - when serializing we can check for _seconds
  if (v && typeof v === 'object' && v._seconds !== undefined && v._nanoseconds !== undefined) {
    return new Date(v._seconds * 1000 + Math.floor(v._nanoseconds / 1000000)).toISOString();
  }
  // GeoPoint in admin may have latitude/longitude properties
  if (v && typeof v === 'object' && v.latitude !== undefined && v.longitude !== undefined) {
    return { lat: v.latitude, lng: v.longitude };
  }
  if (v && typeof v === 'object') {
    const out = {};
    for (const k of Object.keys(v)) out[k] = firestoreValueToJson(v[k]);
    return out;
  }
  return v;
}

function askYesNo(prompt) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(prompt + ' (y/N): ', (answer) => {
      rl.close();
      const normalized = (answer || '').trim().toLowerCase();
      resolve(normalized === 'y' || normalized === 'yes');
    });
  });
}

async function run() {
  const opts = parseArgs();
  if (!opts.serviceAccount || !opts.firestoreDocPath || !opts.rtBasePath) printUsageAndExit();

  const saPath = path.resolve(opts.serviceAccount);
  if (!fs.existsSync(saPath)) {
    console.error('service account key not found at', saPath);
    process.exit(1);
  }

  const serviceAccount = require(saPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`,
  });

  const firestore = admin.firestore();
  const rtdb = admin.database();

  const tables = opts.tables ? opts.tables.split(',') : ['Teams','Seasons','Players','Games','Events'];

  console.log('Migrating collections:', tables.join(', '));
  console.log('From Firestore doc path:', opts.firestoreDocPath);
  console.log('To RTDB base path:', opts.rtBasePath);
  console.log(opts.dryRun ? 'DRY RUN: no writes will be performed' : 'This will write to Realtime Database');

  // Collect data and existing RTDB info
  const planned = [];
  for (const table of tables) {
    console.log(`\nReading collection ${table}...`);
    const colRef = firestore.doc(opts.firestoreDocPath).collection(table);
    const snapshot = await colRef.get();
    const tableMap = {};
    snapshot.forEach(doc => {
      const data = doc.data();
      tableMap[doc.id] = firestoreValueToJson(data);
    });

    // Check existing RTDB data
    const rtRef = rtdb.ref(`${opts.rtBasePath}/${table}`);
    const rtSnap = await rtRef.get();
    const exists = rtSnap.exists();
    const existingCount = exists && rtSnap.val() && typeof rtSnap.val() === 'object'
      ? Object.keys(rtSnap.val()).length
      : (exists ? 1 : 0);

    planned.push({ table, count: Object.keys(tableMap).length, tableMap, exists, existingCount });
    console.log(`  Found ${Object.keys(tableMap).length} docs. Target exists: ${exists ? 'yes' : 'no'} (existing items: ${existingCount})`);
  }

  // Summary
  console.log('\nSummary:');
  for (const p of planned) {
    console.log(`  - ${p.table}: will write ${p.count} docs. Target exists: ${p.exists ? 'yes' : 'no'} (existing: ${p.existingCount})`);
  }

  if (opts.dryRun) {
    console.log('\nDry run requested; no changes will be made.');
    process.exit(0);
  }

  if (!opts.yes) {
    const ok = await askYesNo('\nProceed with the migration and overwrite target paths (backups will be created when existing data is found unless --no-backup is passed)?');
    if (!ok) {
      console.log('Aborted by user.');
      process.exit(0);
    }
  }

  // Mark importing flag on base path
  try {
    await rtdb.ref(opts.rtBasePath).update({ isImporting: true });
  } catch (e) {
    console.warn('Warning: could not set isImporting flag:', e.message || e);
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupRoot = `${opts.rtBasePath}/__backups__/${timestamp}`;

  for (const p of planned) {
    const table = p.table;
    const rtTableRef = rtdb.ref(`${opts.rtBasePath}/${table}`);

    if (p.exists && !opts.noBackup) {
      try {
        console.log(`Backing up existing ${table} to ${backupRoot}/${table} ...`);
        const existingSnap = await rtdb.ref(`${opts.rtBasePath}/${table}`).get();
        if (existingSnap.exists()) {
          await rtdb.ref(`${backupRoot}/${table}`).set(existingSnap.val());
        }
      } catch (e) {
        console.error('Failed to backup existing data for', table, e);
        // Continue, but warn the user
      }
    }

    console.log(`Writing ${p.count} docs to ${opts.rtBasePath}/${table} ...`);
    try {
      await rtTableRef.set(p.tableMap);
    } catch (e) {
      console.error('Failed to write table', table, e);
    }
  }

  // Clear importing flag
  try {
    await rtdb.ref(opts.rtBasePath).update({ isImporting: false });
  } catch (e) {
    console.warn('Warning: could not clear isImporting flag:', e.message || e);
  }

  console.log('\nMigration finished. Backups (if any) are stored under:');
  console.log(`  ${opts.rtBasePath}/__backups__/${timestamp}/`);
  process.exit(0);
}

run().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
