import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserPostRecord extends FirestoreRecord {
  UserPostRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "song_name" field.
  String? _songName;
  String get songName => _songName ?? '';
  bool hasSongName() => _songName != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "post_user" field.
  DocumentReference? _postUser;
  DocumentReference? get postUser => _postUser;
  bool hasPostUser() => _postUser != null;

  // "emoji" field.
  String? _emoji;
  String get emoji => _emoji ?? '';
  bool hasEmoji() => _emoji != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _songName = snapshotData['song_name'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _postUser = snapshotData['post_user'] as DocumentReference?;
    _emoji = snapshotData['emoji'] as String?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('userPost')
          : FirebaseFirestore.instance.collectionGroup('userPost');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('userPost').doc(id);

  static Stream<UserPostRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserPostRecord.fromSnapshot(s));

  static Future<UserPostRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserPostRecord.fromSnapshot(s));

  static UserPostRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UserPostRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserPostRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserPostRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserPostRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserPostRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserPostRecordData({
  String? songName,
  DateTime? createdAt,
  DocumentReference? postUser,
  String? emoji,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'song_name': songName,
      'created_at': createdAt,
      'post_user': postUser,
      'emoji': emoji,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserPostRecordDocumentEquality implements Equality<UserPostRecord> {
  const UserPostRecordDocumentEquality();

  @override
  bool equals(UserPostRecord? e1, UserPostRecord? e2) {
    return e1?.songName == e2?.songName &&
        e1?.createdAt == e2?.createdAt &&
        e1?.postUser == e2?.postUser &&
        e1?.emoji == e2?.emoji;
  }

  @override
  int hash(UserPostRecord? e) => const ListEquality()
      .hash([e?.songName, e?.createdAt, e?.postUser, e?.emoji]);

  @override
  bool isValidKey(Object? o) => o is UserPostRecord;
}
