// In-memory replacement for the Cloud Firestore *platform* layer.
//
// Production code talks to `FirebaseFirestore.instance` directly, so a fake
// `FirebaseFirestore` object cannot be injected. Instead this fake is
// registered as `FirebaseFirestorePlatform.instance`: the real `cloud_firestore`
// package code still runs (references, queries, codec, snapshots), only the
// native/network layer underneath it is replaced by a Map.
//
// Supported: doc get/set/update/delete/snapshots, collection & collection
// group queries with where / orderBy / limit / startAfterDocument, get and
// snapshots, FieldValue.increment / delete / serverTimestamp / arrayUnion /
// arrayRemove. Anything else throws UnimplementedError so a test never
// silently passes on an unsupported operation.

// ignore_for_file: implementation_imports, invalid_use_of_protected_member

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value.dart';
import 'package:collection/collection.dart';
import 'package:firebase_core/firebase_core.dart';

class FakeFirestore extends FirebaseFirestorePlatform {
  FakeFirestore() : super(databaseChoice: '(default)');

  /// Document path -> stored (platform-encoded) data.
  final Map<String, Map<String, dynamic>> _docs = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Every write that reached the "server", in order: `set:<path>`,
  /// `update:<path>`, `delete:<path>`.
  final List<String> writeLog = [];

  /// When non-null, every write throws this instead of being stored.
  Object? failWritesWith;

  void reset() {
    _docs.clear();
    writeLog.clear();
    failWritesWith = null;
  }

  // ------------------------------------------------------------ test helpers

  /// Stores [data] at [path] as if it already existed on the server.
  /// Accepts DateTime and cloud_firestore DocumentReference values.
  void seed(String path, Map<String, dynamic> data) {
    _docs[path] = _encodeMap(data);
  }

  bool exists(String path) => _docs.containsKey(path);

  /// Raw stored data of a document (Timestamps converted back to DateTime,
  /// references to their path), or null when it does not exist.
  Map<String, dynamic>? data(String path) {
    final raw = _docs[path];
    if (raw == null) return null;
    return raw.map((k, v) => MapEntry(k, _plain(v)));
  }

  /// Paths of documents directly inside [collectionPath].
  List<String> docsIn(String collectionPath) =>
      _docs.keys.where((p) => _parentOf(p) == collectionPath).toList()..sort();

  /// Paths of documents in every collection named [collectionId].
  List<String> collectionGroup_(String collectionId) => _docs.keys
      .where((p) => _collectionIdOf(p) == collectionId)
      .toList()
    ..sort();

  // ------------------------------------------------------- platform surface

  @override
  FirebaseFirestorePlatform delegateFor({
    required FirebaseApp app,
    required String databaseId,
  }) =>
      this;

  @override
  CollectionReferencePlatform collection(String collectionPath) =>
      FakeCollectionReference(this, collectionPath);

  @override
  QueryPlatform collectionGroup(String collectionPath) =>
      FakeQuery(this, collectionPath, isGroup: true);

  @override
  DocumentReferencePlatform doc(String documentPath) =>
      FakeDocumentReference(this, documentPath);

  // ---------------------------------------------------------------- storage

  Future<void> _write(String op, String path, void Function() apply) async {
    // Writes complete asynchronously, like a real round trip.
    await Future<void>.delayed(Duration.zero);
    final failure = failWritesWith;
    if (failure != null) throw failure;
    apply();
    writeLog.add('$op:$path');
    _changes.add(null);
  }

  DocumentSnapshotPlatform _snapshot(String path) => DocumentSnapshotPlatform(
        this,
        path,
        _docs[path] == null ? null : Map<String, dynamic>.from(_docs[path]!),
        PigeonSnapshotMetadata(hasPendingWrites: false, isFromCache: false),
      );

  Map<String, dynamic> _encodeMap(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, _encode(v)));

  dynamic _encode(dynamic value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is DocumentReference) return FakeDocumentReference(this, value.path);
    if (value is Map) {
      return value.map((k, v) => MapEntry(k as String, _encode(v)));
    }
    if (value is Iterable) return value.map(_encode).toList();
    return value;
  }

  dynamic _plain(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DocumentReferencePlatform) return value.path;
    if (value is Map) return value.map((k, v) => MapEntry(k, _plain(v)));
    if (value is List) return value.map(_plain).toList();
    return value;
  }

  dynamic _applyFieldValue(dynamic current, dynamic value) {
    if (value is! FieldValuePlatform) return _encode(value);
    final delegate = FieldValuePlatform.getDelegate(value);
    if (delegate is! MethodChannelFieldValue) {
      throw UnimplementedError('FieldValue delegate $delegate');
    }
    switch (delegate.type) {
      case FieldValueType.incrementInteger:
      case FieldValueType.incrementDouble:
        return ((current as num?) ?? 0) + (delegate.value as num);
      case FieldValueType.serverTimestamp:
        return Timestamp.now();
      case FieldValueType.arrayUnion:
        final list = List<dynamic>.from((current as List?) ?? const []);
        for (final item in (delegate.value as List).map(_encode)) {
          if (!list.contains(item)) list.add(item);
        }
        return list;
      case FieldValueType.arrayRemove:
        final remove = (delegate.value as List).map(_encode).toList();
        return List<dynamic>.from((current as List?) ?? const [])
          ..removeWhere(remove.contains);
      case FieldValueType.delete:
        return _deleteMarker;
    }
  }

  static final Object _deleteMarker = Object();

  static String? _parentOf(String docPath) {
    final i = docPath.lastIndexOf('/');
    return i < 0 ? null : docPath.substring(0, i);
  }

  static String? _collectionIdOf(String docPath) {
    final parts = docPath.split('/');
    return parts.length < 2 ? null : parts[parts.length - 2];
  }
}

class FakeDocumentReference extends DocumentReferencePlatform {
  FakeDocumentReference(this._fs, String path) : super(_fs, path);

  final FakeFirestore _fs;

  @override
  Future<DocumentSnapshotPlatform> get([
    GetOptions options = const GetOptions(),
  ]) async {
    await Future<void>.delayed(Duration.zero);
    return _fs._snapshot(path);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      _fs._write('set', path, () {
        final merge = options?.merge ?? false;
        final base =
            merge ? Map<String, dynamic>.from(_fs._docs[path] ?? {}) : <String, dynamic>{};
        data.forEach((key, value) {
          final next = _fs._applyFieldValue(base[key], value);
          if (identical(next, FakeFirestore._deleteMarker)) {
            base.remove(key);
          } else {
            base[key] = next;
          }
        });
        _fs._docs[path] = base;
      });

  @override
  Future<void> update(Map<FieldPath, dynamic> data) =>
      _fs._write('update', path, () {
        final current = _fs._docs[path];
        if (current == null) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'No document to update: $path',
          );
        }
        data.forEach((fieldPath, value) {
          final key = fieldPath.components.join('.');
          final next = _fs._applyFieldValue(current[key], value);
          if (identical(next, FakeFirestore._deleteMarker)) {
            current.remove(key);
          } else {
            current[key] = next;
          }
        });
      });

  @override
  Future<void> delete() =>
      _fs._write('delete', path, () => _fs._docs.remove(path));

  @override
  Stream<DocumentSnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
    required ListenSource listenSource,
  }) {
    // Broadcast, like the real plugin: the app may listen more than once.
    late StreamController<DocumentSnapshotPlatform> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<DocumentSnapshotPlatform>.broadcast(
      onListen: () {
        controller.add(_fs._snapshot(path));
        sub = _fs._changes.stream
            .listen((_) => controller.add(_fs._snapshot(path)));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }
}

class FakeQuery extends QueryPlatform {
  FakeQuery(
    this._fs,
    this._path, {
    this.isGroup = false,
    Map<String, dynamic>? parameters,
  }) : super(_fs, parameters);

  final FakeFirestore _fs;
  final String _path;
  final bool isGroup;

  @override
  bool get isCollectionGroupQuery => isGroup;

  FakeQuery _copy(Map<String, dynamic> changes) => FakeQuery(
        _fs,
        _path,
        isGroup: isGroup,
        parameters: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(parameters)..addAll(changes),
        ),
      );

  @override
  QueryPlatform where(List<List<dynamic>> conditions) =>
      _copy({'where': conditions});

  @override
  QueryPlatform orderBy(Iterable<List<dynamic>> orders) =>
      _copy({'orderBy': orders.toList()});

  @override
  QueryPlatform limit(int limit) => _copy({'limit': limit, 'limitToLast': null});

  @override
  QueryPlatform startAfterDocument(List<dynamic> orders, List<dynamic> values) =>
      _copy({'orderBy': orders, 'startAfter': values, 'startAt': null});

  @override
  Future<QuerySnapshotPlatform> get([
    GetOptions options = const GetOptions(),
  ]) async {
    await Future<void>.delayed(Duration.zero);
    return _run();
  }

  @override
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
    required ListenSource listenSource,
  }) {
    // Broadcast, like the real plugin: the app may listen more than once.
    late StreamController<QuerySnapshotPlatform> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<QuerySnapshotPlatform>.broadcast(
      onListen: () {
        controller.add(_run());
        sub = _fs._changes.stream.listen((_) => controller.add(_run()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  QuerySnapshotPlatform _run() {
    var paths = isGroup ? _fs.collectionGroup_(_path) : _fs.docsIn(_path);

    final conditions = (parameters['where'] as List?) ?? const [];
    for (final condition in conditions) {
      final c = condition as List;
      paths = paths.where((p) => _matches(p, c[0], c[1] as String, c[2])).toList();
    }

    final orders = ((parameters['orderBy'] as List?) ?? const []).cast<List>();
    if (orders.isNotEmpty) {
      paths = paths
          .where((p) => orders.every((o) => _field(p, o[0]) != null))
          .toList()
        ..sort((a, b) {
          for (final o in orders) {
            final cmp = _compare(_field(a, o[0]), _field(b, o[0]));
            if (cmp != 0) return (o[1] as bool) ? -cmp : cmp;
          }
          return a.compareTo(b);
        });
    }

    final startAfter = parameters['startAfter'] as List?;
    if (startAfter != null && orders.isNotEmpty) {
      paths = paths.where((p) {
        for (var i = 0; i < orders.length && i < startAfter.length; i++) {
          var cmp = _compare(_field(p, orders[i][0]), _norm(startAfter[i]));
          if (orders[i][1] as bool) cmp = -cmp;
          if (cmp != 0) return cmp > 0;
        }
        return false;
      }).toList();
    }

    final limit = parameters['limit'] as int?;
    if (limit != null) paths = paths.take(limit).toList();

    final docs = paths.map(_fs._snapshot).toList();
    final changes = [
      for (var i = 0; i < docs.length; i++)
        DocumentChangePlatform(DocumentChangeType.added, -1, i, docs[i]),
    ];
    return QuerySnapshotPlatform(
      docs,
      changes,
      SnapshotMetadataPlatform(false, false),
    );
  }

  dynamic _field(String docPath, dynamic fieldPath) {
    if (fieldPath == FieldPath.documentId) return docPath;
    final key = (fieldPath as FieldPath).components.join('.');
    return _norm(_fs._docs[docPath]?[key]);
  }

  bool _matches(String docPath, dynamic fieldPath, String op, dynamic rawValue) {
    final actual = _field(docPath, fieldPath);
    final value = rawValue is Iterable
        ? rawValue.map(_norm).toList()
        : _norm(rawValue);
    const eq = DeepCollectionEquality();
    switch (op) {
      case '==':
        return eq.equals(actual, value);
      case '!=':
        return actual != null && !eq.equals(actual, value);
      case '<':
        return actual != null && _compare(actual, value) < 0;
      case '<=':
        return actual != null && _compare(actual, value) <= 0;
      case '>':
        return actual != null && _compare(actual, value) > 0;
      case '>=':
        return actual != null && _compare(actual, value) >= 0;
      case 'array-contains':
        return actual is List && actual.any((e) => eq.equals(e, value));
      case 'array-contains-any':
        return actual is List &&
            actual.any((e) => (value as List).any((v) => eq.equals(e, v)));
      case 'in':
        return (value as List).any((v) => eq.equals(actual, v));
      case 'not-in':
        return actual != null && !(value as List).any((v) => eq.equals(actual, v));
    }
    throw UnimplementedError('where operator $op');
  }

  /// Normalises values so they compare the way Firestore compares them.
  static dynamic _norm(dynamic value) {
    if (value is DateTime) return value.microsecondsSinceEpoch;
    if (value is Timestamp) return value.microsecondsSinceEpoch;
    if (value is DocumentReferencePlatform) return value.path;
    if (value is DocumentReference) return value.path;
    if (value is List) return value.map(_norm).toList();
    return value;
  }

  static int _compare(dynamic a, dynamic b) {
    if (a is num && b is num) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    if (a is bool && b is bool) return (a ? 1 : 0) - (b ? 1 : 0);
    return '${a ?? ''}'.compareTo('${b ?? ''}');
  }

  @override
  bool operator ==(Object other) =>
      other is FakeQuery &&
      other.runtimeType == runtimeType &&
      other._path == _path &&
      other.isGroup == isGroup &&
      const DeepCollectionEquality().equals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(_path, isGroup);
}

class FakeCollectionReference extends FakeQuery
    implements CollectionReferencePlatform {
  FakeCollectionReference(FakeFirestore fs, String path) : super(fs, path);

  static final Random _random = Random(42);

  @override
  String get path => _path;

  @override
  String get id => _path.split('/').last;

  @override
  DocumentReferencePlatform? get parent {
    final i = _path.lastIndexOf('/');
    return i < 0 ? null : _fs.doc(_path.substring(0, i));
  }

  @override
  DocumentReferencePlatform doc([String? path]) {
    final id = path ??
        List.generate(20, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[
            _random.nextInt(36)]).join();
    return FakeDocumentReference(_fs, '$_path/$id');
  }
}
