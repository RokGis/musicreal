import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MusicRecord extends FirestoreRecord {
  MusicRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "SongURL" field.
  String? _songURL;
  String get songURL => _songURL ?? '';
  bool hasSongURL() => _songURL != null;

  // "SongName" field.
  String? _songName;
  String get songName => _songName ?? '';
  bool hasSongName() => _songName != null;

  // "Author" field.
  String? _author;
  String get author => _author ?? '';
  bool hasAuthor() => _author != null;

  // "Genres" field.
  List<String>? _genres;
  List<String> get genres => _genres ?? const [];
  bool hasGenres() => _genres != null;

  void _initializeFields() {
    _songURL = snapshotData['SongURL'] as String?;
    _songName = snapshotData['SongName'] as String?;
    _author = snapshotData['Author'] as String?;
    _genres = getDataList(snapshotData['Genres']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Music');

  static Stream<MusicRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MusicRecord.fromSnapshot(s));

  static Future<MusicRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MusicRecord.fromSnapshot(s));

  static MusicRecord fromSnapshot(DocumentSnapshot snapshot) => MusicRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MusicRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MusicRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MusicRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MusicRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMusicRecordData({
  String? songURL,
  String? songName,
  String? author,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'SongURL': songURL,
      'SongName': songName,
      'Author': author,
    }.withoutNulls,
  );

  return firestoreData;
}

class MusicRecordDocumentEquality implements Equality<MusicRecord> {
  const MusicRecordDocumentEquality();

  @override
  bool equals(MusicRecord? e1, MusicRecord? e2) {
    const listEquality = ListEquality();
    return e1?.songURL == e2?.songURL &&
        e1?.songName == e2?.songName &&
        e1?.author == e2?.author &&
        listEquality.equals(e1?.genres, e2?.genres);
  }

  @override
  int hash(MusicRecord? e) => const ListEquality()
      .hash([e?.songURL, e?.songName, e?.author, e?.genres]);

  @override
  bool isValidKey(Object? o) => o is MusicRecord;
}
