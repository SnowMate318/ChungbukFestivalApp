const APP_COLLECTIONS = [
  "festivalUsers",
  "seedCategories",
  "seeds",
  "smsRequests",
  "uniqueNicknames",
  "uniquePhoneNumbers",
  "uniqueSeedNames",
  "uniqueCategoryNames",
  "settings",
  "metrics",
];

const args = process.argv.slice(2);
const flags = new Set(args);
const confirmed = flags.has("--confirm") || flags.has("--yes");
const deleteAllCollections = flags.has("--all");
const batchSize = readNumberArg("--batch-size", 250);
const projectId =
  readStringArg("--project") ||
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  "greenfestival-5320b";

if (!confirmed) {
  printDryRunHelp();
  process.exit(0);
}

const admin = require("firebase-admin");

admin.initializeApp({ projectId });

const db = admin.firestore();

run().catch((error) => {
  console.error("[resetFirestore] Failed:", error);
  process.exitCode = 1;
});

async function run() {
  console.log(`[resetFirestore] Project: ${projectId}`);
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log(
      `[resetFirestore] Emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`,
    );
  }

  const collectionIds = deleteAllCollections
    ? await listRootCollectionIds()
    : APP_COLLECTIONS;

  if (collectionIds.length === 0) {
    console.log("[resetFirestore] Nothing to delete.");
    return;
  }

  console.log(
    `[resetFirestore] Deleting ${collectionIds.length} collection(s): ${collectionIds.join(", ")}`,
  );

  let totalDeleted = 0;
  for (const collectionId of collectionIds) {
    const deleted = await deleteCollection(db.collection(collectionId));
    totalDeleted += deleted;
    console.log(`[resetFirestore] ${collectionId}: ${deleted} document(s)`);
  }

  console.log(`[resetFirestore] Done. Deleted ${totalDeleted} document(s).`);
}

async function listRootCollectionIds() {
  const collections = await db.listCollections();
  return collections.map((collection) => collection.id).sort();
}

async function deleteCollection(collectionRef) {
  let deleted = 0;

  while (true) {
    const snapshot = await collectionRef.limit(batchSize).get();
    if (snapshot.empty) {
      return deleted;
    }

    for (const doc of snapshot.docs) {
      deleted += await deleteDocumentTree(doc.ref);
    }
  }
}

async function deleteDocumentTree(docRef) {
  const childCollections = await docRef.listCollections();
  let deleted = 0;

  for (const childCollection of childCollections) {
    deleted += await deleteCollection(childCollection);
  }

  await docRef.delete();
  return deleted + 1;
}

function readStringArg(name) {
  const index = args.indexOf(name);
  if (index === -1 || index === args.length - 1) {
    return "";
  }
  return String(args[index + 1] || "").trim();
}

function readNumberArg(name, fallback) {
  const rawValue = readStringArg(name);
  const value = Number(rawValue);
  if (!Number.isFinite(value) || value < 1) {
    return fallback;
  }
  return Math.min(Math.floor(value), 500);
}

function printDryRunHelp() {
  console.log("Firestore reset script is in dry-run mode.");
  console.log("");
  console.log("This deletes the app collections:");
  console.log(`  ${APP_COLLECTIONS.join(", ")}`);
  console.log("");
  console.log("Run one of these when you are sure:");
  console.log("  npm run reset:firestore -- --confirm");
  console.log("  npm.cmd run reset:firestore -- --confirm");
  console.log("  ..\\scripts\\reset_firestore.ps1 -Confirm");
  console.log("  npm run reset:firestore -- --confirm --all");
  console.log("");
  console.log("Optional:");
  console.log("  --project <firebase-project-id>");
  console.log("  --batch-size <1-500>");
}
