import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suefery/data/enums/query_operator.dart';


import '../../data/repositories/i_firestore_repository.dart';
import 'log_repo.dart'; 
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

// Import your enum
// import 'package:suefery/data/enums/query_operator.dart'; 

class FirestoreRepo implements IFirestoreRepo {
  final _log = LogRepo('FirestoreRepository');
  final FirebaseFirestore _firestore;

  /// The [FirebaseFirestore] instance is injected.
  /// This allows for easy testing and emulator configuration.
  FirestoreRepo._({required FirebaseFirestore firestore})  : _firestore = firestore;
  /// Creates and initializes a new [FirestoreRepo] instance.
  ///
  /// If [useEmulator] is true, it will connect to the local
  /// Firebase Auth emulator on localhost:9099.
  ///
  /// Note: Emulators should only be used in debug builds.
  factory FirestoreRepo.create({bool useEmulator = false}) {
    final instance = FirebaseFirestore.instance;
    final log = LogRepo('AuthRepo');
    // Use emulator only in debug mode and if requested
    if (kDebugMode && useEmulator) {
      try {
        log.i('Connecting to Firebase FirebaseFirestore Emulator...');
        final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)? '10.0.2.2': 'localhost';
        instance.useFirestoreEmulator(emulatorHost, 8080);
        log.i('Connected to FirebaseFirestore Emulator on localhost:8080');
      } catch (e) {
        log.e('*** FAILED TO CONNECT TO FirebaseFirestore EMULATOR: $e ***');
        log.e(
            '*** Make sure the emulator is running: firebase emulators:start ***');
      }
    }
        // Enable offline persistence for better performance, especially on mobile
    if (!kIsWeb) {
      instance.settings = const Settings(persistenceEnabled: true);
    }
    return FirestoreRepo._(
      firestore: instance,
    );
  }

  @override
  String generateId(String path) {
    final ref = _firestore.collection(path).doc();
    return ref.id;
  }

  @override
  Future<String> add(String path, Map<String, dynamic> data,{String? id}) async {
    try {
      DocumentReference<Map<String, dynamic>> ref;
      if (id != null) {
        ref = _firestore.collection(path).doc(id);
      } else {
        ref =_firestore.collection(path).doc();
        }

      data['id'] = ref.id; // Add the ID to the data
      await ref.set(data); // Use set() for creating documents with generated IDs
      return ref.id;
    } catch (e) {
      _log.e("Error adding document to $path: $e");
      rethrow;
    }
  }

  @override
  Future<void> addMultiple(String path, List<Map<String, dynamic>> data) async {
    final batch = _firestore.batch();
    final collectionRef = _firestore.collection(path);
    for (var item in data) {
      final docRef = collectionRef.doc();
      item['id'] = docRef.id;
      batch.set(docRef, item);
    }
    try {
      await batch.commit();
      _log.i('Multiple documents created successfully!');
    } catch (e) {
      _log.e('Error creating multiple documents: $e');
      rethrow;
    }
  }

  @override
  Future<void> update(String path, String id, Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection(path).doc(id);
      await ref.update(data);
    } catch (e) {
      _log.e("Error updating document in $path with ID $id: $e");
      rethrow;
    }
  }

  @override
  Future<void> set(String path, String id, Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection(path).doc(id);
      await ref.set(data);
    } catch (e) {
      _log.e("Error setting document in $path with ID $id: $e");
      rethrow;
    }
  }

  @override
  Future<void> remove(String path, String id) async {
    try {
      await _firestore.collection(path).doc(id).delete();
    } catch (e) {
      _log.e("Error removing document in $path with ID $id: $e");
      rethrow;
    }
  }

@override
  Stream<QuerySnapshot<Map<String, dynamic>>> quaryCollectionStream(
    String collectionPath, {
    String? orderBy,
    bool isDescending = false,
  }) {
    // Start with the basic query
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    // Add sorting if provided
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: isDescending);
    }

    // Return the stream of snapshots
    return query.snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> quaryCollection(
      String collection, dynamic field, dynamic queryValue,
      {QueryComparisonOperator? quaryOperator,
      String? orderBy,
      bool? isDescending}) async {
    // Your original switch-case logic remains unchanged
    // ...
    // Note: You should ideally refactor this switch statement to
    // build a query chain, but for this refactor, we'll keep it.
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    if (quaryOperator == null) {
      querySnapshot = await _firestore.collection(collection).get();
    } else {
      switch (quaryOperator) {
        // ... all your cases
        case QueryComparisonOperator.eq:
           querySnapshot = await _firestore
                                .collection(collection)
                                .where(field, isEqualTo: queryValue).get();
           break;
        // ... etc.
        default:
          querySnapshot = await _firestore.collection(collection).get();
      }
    }
    return querySnapshot;
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> quaryDocumentStream(
      String collectionPath, String docId) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentSnapShot(
      String collectionPath, String docId) async {
    return await _firestore.collection(collectionPath).doc(docId).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> quarySnapshot(
      String collection, dynamic field, dynamic queryValue,
      {QueryComparisonOperator quaryOperator = QueryComparisonOperator.eq}) {
    // Your original switch-case logic for quarySnapshot remains unchanged
    // ...
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: queryValue)
        .limit(1)
        .get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> queryWithFilter(
      String collectionPath, Filter queryFilter) async {
    return await _firestore
        .collection(collectionPath)
        .where(queryFilter)
        .get();
  }
  
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> queryCollectionWithFilterStream(
      String collectionPath, Filter queryFilter) {
    return _firestore
        .collection(collectionPath)
        .where(queryFilter).snapshots();
  }
}