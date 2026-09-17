const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const firestore = admin.firestore();
  const userRef = firestore.collection("users").doc(user.uid);

  const [friendOf, sent, received] = await Promise.all([
    firestore.collection("users").where("friends", "array-contains", userRef).get(),
    firestore.collection("friend_requests").where("sender", "==", userRef).get(),
    firestore.collection("friend_requests").where("receiver", "==", userRef).get(),
  ]);

  const writer = firestore.bulkWriter();
  friendOf.forEach((doc) =>
    writer.update(doc.ref, {
      friends: admin.firestore.FieldValue.arrayRemove(userRef),
    })
  );
  sent.forEach((doc) => writer.delete(doc.ref));
  received.forEach((doc) => writer.delete(doc.ref));
  await writer.close();

  // Removes the user document together with its userPost subcollection.
  await firestore.recursiveDelete(userRef);
});
