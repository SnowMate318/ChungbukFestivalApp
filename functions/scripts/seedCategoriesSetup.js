const fs = require("fs");
const path = require("path");

const admin = require("firebase-admin");

const CATEGORY_FIXTURES = [
  { name: "전시" },
  { name: "교육" },
  { name: "체험" },
  { name: "홍보" },
  { name: "다회용기 사용" },
  { name: "깨끗하게 식사 후 먹기" },
];

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
  console.error("[seedCategoriesSetup] Failed:", error);
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
    console.log(
      `[seedCategoriesSetup] Using service account: ${serviceAccountPath}`,
    );
    return;
  }

  admin.initializeApp({ projectId });
  console.log("[seedCategoriesSetup] Using application default credentials.");
}

async function run() {
  console.log(`[seedCategoriesSetup] Project: ${projectId}`);
  console.log(
    `[seedCategoriesSetup] Upserting ${CATEGORY_FIXTURES.length} categories...`,
  );

  for (const category of CATEGORY_FIXTURES) {
    const result = await upsertCategory(category);
    console.log(
      `[seedCategoriesSetup] ${result.action}: ${category.name} (${result.uid})`,
    );
  }

  console.log("[seedCategoriesSetup] Done.");
}

async function upsertCategory(category) {
  const normalizedName = String(category.name || "").trim();

  if (!normalizedName) {
    throw new Error("Category name is required.");
  }

  const uniqueKey = toUniqueKey(normalizedName);
  const uniqueRef = db.collection("uniqueCategoryNames").doc(uniqueKey);
  const uniqueSnapshot = await uniqueRef.get();

  let categoryRef;
  let created = false;

  if (uniqueSnapshot.exists) {
    const uid = String(uniqueSnapshot.get("uid") || "").trim();
    if (uid) {
      categoryRef = db.collection("seedCategories").doc(uid);
    }
  }

  if (!categoryRef) {
    const existingByName = await db
      .collection("seedCategories")
      .where("name", "==", normalizedName)
      .limit(1)
      .get();

    if (!existingByName.empty) {
      categoryRef = existingByName.docs[0].ref;
    } else {
      categoryRef = db.collection("seedCategories").doc();
      created = true;
    }
  }

  const categorySnapshot = await categoryRef.get();
  const serverNow = admin.firestore.FieldValue.serverTimestamp();

  await categoryRef.set(
    {
      uid: categoryRef.id,
      name: normalizedName,
      createdAt: categorySnapshot.exists
        ? categorySnapshot.get("createdAt") || serverNow
        : serverNow,
      updatedAt: serverNow,
    },
    { merge: true },
  );

  await uniqueRef.set(
    {
      uid: categoryRef.id,
      value: normalizedName,
      createdAt: uniqueSnapshot.exists
        ? uniqueSnapshot.get("createdAt") || serverNow
        : serverNow,
      updatedAt: serverNow,
    },
    { merge: true },
  );

  return {
    action: created ? "created" : "updated",
    uid: categoryRef.id,
  };
}

function toUniqueKey(value) {
  return Buffer.from(String(value).trim().toLowerCase(), "utf8")
    .toString("base64url")
    .replace(/=/g, "");
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
  console.log("Seed category setup script is in dry-run mode.");
  console.log("");
  console.log("This will upsert these categories into Firestore:");
  for (const category of CATEGORY_FIXTURES) {
    console.log(`- ${category.name}`);
  }
  console.log("");
  console.log("Run one of these when you are ready:");
  console.log("  npm run seed:categories -- --confirm");
  console.log("  npm.cmd run seed:categories -- --confirm");
  console.log(
    "  node scripts/seedCategoriesSetup.js --confirm --project greenfestival-5320b",
  );
  console.log("");
  console.log("Optional:");
  console.log("  --service-account <absolute-or-relative-path-to-json>");
}
