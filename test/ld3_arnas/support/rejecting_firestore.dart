// LD3 – Arnas: Manto platformos lygio Firestore pakaitalas, kuris gali atmesti
// srauto užklausą (collectionGroup('userPost')), kaip ją atmestų platformos SDK
// ar serveris.
//
// Debug režimu cloud_firestore Dart kodas užklausą su > 30 'in' reikšmių
// sustabdo assert'u dar prieš platformą. Release režimu assert'ai pašalinami,
// todėl užklausa pasiekia platformą ir ten atmetama – srautas baigiasi klaida.
// Šis pakaitalas modeliuoja būtent tą klaidą.

// ignore_for_file: implementation_imports

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import '../../mantas/support/fake_firestore.dart';

class RejectableFirestore extends FakeFirestore {
  bool rejectFeedQuery = false;

  @override
  QueryPlatform collectionGroup(String collectionPath) =>
      rejectFeedQuery && collectionPath == 'userPost'
          ? _RejectedFeedQuery(this)
          : super.collectionGroup(collectionPath);
}

class _RejectedFeedQuery extends FakeQuery {
  _RejectedFeedQuery(FakeFirestore fs) : super(fs, 'userPost', isGroup: true);

  @override
  QueryPlatform where(List<List<dynamic>> conditions) => this;

  @override
  QueryPlatform orderBy(Iterable<List<dynamic>> orders) => this;

  @override
  QueryPlatform limit(int limit) => this;

  @override
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
    required ListenSource listenSource,
  }) =>
      Stream.error(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: "modeled: platform rejected the feed query ('in' filter with more than 30 values)",
      ));
}
