/**
 * One-time: create Firebase Auth user (if missing), set custom claims, add Firestore `admins` doc.
 *
 * Requires Admin SDK credentials (one of):
 *   - `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json`
 *   - or run after `gcloud auth application-default login`
 *
 * Usage (password via env only — never commit secrets):
 *   cd functions
 *   SEED_ADMIN_EMAIL=admin@quickgroceries.in SEED_ADMIN_PASSWORD='YourSecurePassword' npm run seed:admin
 *
 * Optional: UPDATE_PASSWORD=1  →  reset password if user already exists
 */
const admin = require("firebase-admin");

const emailRaw = (process.env.SEED_ADMIN_EMAIL || "").trim();
const password = process.env.SEED_ADMIN_PASSWORD || "";
const updatePassword = process.env.UPDATE_PASSWORD === "1";

if (!emailRaw || !password) {
  console.error(
    "Missing SEED_ADMIN_EMAIL or SEED_ADMIN_PASSWORD. See header in scripts/seed_admin.cjs"
  );
  process.exit(1);
}

const email = emailRaw.toLowerCase();

if (!admin.apps.length) {
  admin.initializeApp();
}

async function main() {
  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    console.log("Auth user already exists:", user.uid);
    if (updatePassword) {
      await admin.auth().updateUser(user.uid, { password });
      console.log("Password updated (UPDATE_PASSWORD=1).");
    }
  } catch (e) {
    if (e.code !== "auth/user-not-found") {
      console.error(e);
      process.exit(1);
    }
    user = await admin.auth().createUser({
      email,
      password,
      emailVerified: true,
    });
    console.log("Created Auth user:", user.uid);
  }

  const claims = {
    admin: true,
    smsAdmin: true,
    notificationsAdmin: true,
    role: "superAdmin",
    superAdmin: true,
  };
  await admin.auth().setCustomUserClaims(user.uid, claims);
  console.log("Custom claims set:", claims);

  const db = admin.firestore();
  const snap = await db.collection("admins").where("email", "==", email).limit(1).get();
  if (snap.empty) {
    await db.collection("admins").add({
      email,
      role: "superAdmin",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log("Added Firestore admins/ document for", email);
  } else {
    console.log("Firestore admins/ already has a row for", email);
  }

  console.log("\nDone. Sign in from the Flutter admin login with this email and password.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
