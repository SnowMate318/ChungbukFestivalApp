const fs = require("fs");
const path = require("path");

const admin = require("firebase-admin");

const args = process.argv.slice(2);
const flags = new Set(args);
const confirmed = flags.has("--confirm") || flags.has("--yes");
const projectId =
  readStringArg("--project") ||
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  "greenfestival-5320b";
const explicitServiceAccount = readStringArg("--service-account");

if (!confirmed) {
  printDryRunHelp();
  process.exit(0);
}

initializeApp();

const db = admin.firestore();

run().catch((error) => {
  console.error("[migrateSeedData] Failed:", error);
  process.exitCode = 1;
});

function initializeApp() {
  const serviceAccountPath = resolveServiceAccountPath(explicitServiceAccount);
  if (serviceAccountPath) {
    const serviceAccount = JSON.parse(
      fs.readFileSync(serviceAccountPath, "utf8"),
    );
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id || projectId,
    });
    console.log(`[migrateSeedData] Using service account: ${serviceAccountPath}`);
    return;
  }

  admin.initializeApp({ projectId });
  console.log("[migrateSeedData] Using application default credentials.");
}

async function run() {
  console.log(`[migrateSeedData] Project: ${projectId}`);

  const seedValueByUid = await migrateSeeds();
  await migrateCategories();
  const totalSeedCount = await migrateUsers(seedValueByUid);
  await db.collection("metrics").doc("summary").set(
    {
      totalSeedCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(`[migrateSeedData] Done. totalSeedCount=${totalSeedCount}`);
}

async function migrateCategories() {
  const snapshot = await db.collection("seedCategories").get();
  if (snapshot.empty) {
    console.log("[migrateSeedData] No seedCategories found.");
    return;
  }

  let batch = db.batch();
  let operations = 0;

  for (const doc of snapshot.docs) {
    batch.update(doc.ref, {
      descriptions: admin.firestore.FieldValue.delete(),
      descriptionList: admin.firestore.FieldValue.delete(),
      description: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    operations += 1;

    if (operations === 400) {
      await batch.commit();
      batch = db.batch();
      operations = 0;
    }
  }

  if (operations > 0) {
    await batch.commit();
  }

  console.log(`[migrateSeedData] Updated ${snapshot.size} categories.`);
}

async function migrateSeeds() {
  const snapshot = await db.collection("seeds").get();
  const seedValueByUid = new Map();

  if (snapshot.empty) {
    console.log("[migrateSeedData] No seeds found.");
    return seedValueByUid;
  }

  let batch = db.batch();
  let operations = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const rawValue = Number.parseInt(
      String(data.seedValue ?? data.seed_value ?? "1"),
      10,
    );
    const seedValue = Number.isFinite(rawValue) && rawValue > 0 ? rawValue : 1;
    seedValueByUid.set(String(data.uid || doc.id), seedValue);

    batch.set(
      doc.ref,
      {
        uid: String(data.uid || doc.id),
        seedValue,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    operations += 1;

    if (operations === 400) {
      await batch.commit();
      batch = db.batch();
      operations = 0;
    }
  }

  if (operations > 0) {
    await batch.commit();
  }

  console.log(`[migrateSeedData] Updated ${snapshot.size} seeds.`);
  return seedValueByUid;
}

async function migrateUsers(seedValueByUid) {
  const snapshot = await db.collection("festivalUsers").get();
  if (snapshot.empty) {
    console.log("[migrateSeedData] No festivalUsers found.");
    return 0;
  }

  let batch = db.batch();
  let operations = 0;
  let totalSeedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const rawSeedCounts = data.seedCounts || data.seed_counts || {};
    const normalizedSeedCounts = {};
    let seedCount = 0;

    for (const [seedUid, rawCount] of Object.entries(rawSeedCounts)) {
      const count = Math.max(0, Number.parseInt(String(rawCount ?? 0), 10) || 0);
      if (count <= 0) {
        continue;
      }
      normalizedSeedCounts[seedUid] = count;
      const seedValue = seedValueByUid.get(seedUid) || 1;
      seedCount += count * seedValue;
    }

    totalSeedCount += seedCount;
    batch.set(
      doc.ref,
      {
        seedCounts: normalizedSeedCounts,
        seedCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    operations += 1;

    if (operations === 400) {
      await batch.commit();
      batch = db.batch();
      operations = 0;
    }
  }

  if (operations > 0) {
    await batch.commit();
  }

  console.log(`[migrateSeedData] Updated ${snapshot.size} users.`);
  return totalSeedCount;
}

function resolveServiceAccountPath(explicitPath) {
  const candidates = [
    explicitPath,
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.resolve(__dirname, "..", "..", "service-account.json"),
    path.resolve(__dirname, "..", "..", "firebase-service-account.json"),
    path.resolve(
      __dirname,
      "..",
      "..",
      "greenfestival-5320b-firebase-adminsdk-fbsvc-d1df188295.json",
    ),
    path.resolve(__dirname, "..", "..", "secrets", "service-account.json"),
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return "";
}

function readStringArg(name) {
  const index = args.indexOf(name);
  if (index === -1 || index === args.length - 1) {
    return "";
  }
  return String(args[index + 1] || "").trim();
}

function printDryRunHelp() {
  console.log("Seed data migration script is in dry-run mode.");
  console.log("");
  console.log("This migration will:");
  console.log("- remove seedCategories.descriptions fields");
  console.log("- fill missing seeds.seedValue with 1");
  console.log("- recalculate festivalUsers.seedCount from seedCounts x seedValue");
  console.log("- refresh metrics.summary.totalSeedCount");
  console.log("");
  console.log("Run one of these when you are ready:");
  console.log("  node scripts/migrateSeedData.js --confirm");
  console.log("  node scripts/migrateSeedData.js --confirm --project greenfestival-5320b");
  console.log("");
  console.log("Optional:");
  console.log("  --service-account <absolute-or-relative-path-to-json>");
}
