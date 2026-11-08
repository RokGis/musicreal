// Shared fixtures: SCRUM-67, SCRUM-49, SCRUM-39, SCRUM-48

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';

final DateTime kNow = DateTime(2026, 10, 3, 12, 0, 0);

const String kHappy = 'https://emoji.test/happy.png';
const String kSad = 'https://emoji.test/sad.png';
const String kCool = 'https://emoji.test/cool.png';

DocumentReference userRef(FakeFirebaseFirestore db, String id) =>
    db.doc('users/$id');

Future<DocumentReference> addUser(
  FakeFirebaseFirestore db,
  String id, {
  String? name,
  List<DocumentReference> friends = const [],
}) async {
  final ref = userRef(db, id);
  await ref.set({
    'uid': id,
    'display_name': name ?? id,
    'friends': friends,
  });
  return ref;
}

Future<void> addPost(
  FakeFirebaseFirestore db,
  DocumentReference author,
  String id, {
  required String song,
  required DateTime createdAt,
  String? emoji = kHappy,
}) =>
    author.collection('userPost').doc(id).set({
      'song_name': song,
      'post_user': author,
      'created_at': createdAt,
      if (emoji != null) 'emoji': emoji,
    });

UserPostRecord post(
  DocumentReference author,
  String id, {
  required String song,
  DateTime? createdAt,
  String? emoji = kHappy,
}) =>
    UserPostRecord.getDocumentFromData({
      'song_name': song,
      'post_user': author,
      if (createdAt != null) 'created_at': createdAt,
      if (emoji != null) 'emoji': emoji,
    }, author.collection('userPost').doc(id));

UsersRecord user(DocumentReference ref, String name) =>
    UsersRecord.getDocumentFromData({
      'uid': ref.id,
      'display_name': name,
    }, ref);

List<String> paths(List<UserPostRecord> posts) =>
    posts.map((p) => p.reference.id).toList();

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

List<String> imageUrls(WidgetTester tester, [Finder? within]) {
  final finder = within == null
      ? find.byType(Image)
      : find.descendant(of: within, matching: find.byType(Image));
  return tester
      .widgetList<Image>(finder)
      .map((image) => image.image)
      .whereType<NetworkImage>()
      .map((image) => image.url)
      .toList();
}
