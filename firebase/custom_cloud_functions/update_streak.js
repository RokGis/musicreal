const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.updateStreak = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid)
    throw new functions.https.HttpsError("unauthenticated", "Not signed in");

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();
  const userData = userDoc.data() || {};

  const today = new Date();
  today.setHours(0, 0, 0, 0); // strip time

  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);

  const lastPostDate = userData.last_post_date
    ? userData.last_post_date.toDate()
    : null;

  if (lastPostDate) {
    lastPostDate.setHours(0, 0, 0, 0); // strip time
  }

  let newStreak = userData.streak_count || 0;

  if (!lastPostDate) {
    // First ever post
    newStreak = 1;
  } else if (lastPostDate.getTime() === today.getTime()) {
    // Already posted today, don't change streak
    return { streak: newStreak };
  } else if (lastPostDate.getTime() === yesterday.getTime()) {
    // Posted yesterday — keep the streak going!
    newStreak += 1;
  } else {
    // Missed a day — reset
    newStreak = 1;
  }

  await userRef.update({
    streak_count: newStreak,
    last_post_date: admin.firestore.Timestamp.fromDate(today),
  });

  return { streak: newStreak };
});
