const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.checkStreakOnOpen = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid)
    throw new functions.https.HttpsError("unauthenticated", "Not signed in");

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();
  const userData = userDoc.data() || {};

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);

  const lastPostDate = userData.last_post_date?.toDate();
  if (lastPostDate) {
    lastPostDate.setHours(0, 0, 0, 0);
    // If last post was before yesterday, streak is broken
    if (lastPostDate.getTime() < yesterday.getTime()) {
      await userRef.update({ streak_count: 0 });
      return { streak: 0 };
    }
  }

  return { streak: userData.streak_count || 0 };
});
