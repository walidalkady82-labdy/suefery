import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:suefery/core/extensions/future_extension.dart';
import 'package:suefery/core/extensions/is_not_null_or_empty.dart';
import 'package:suefery/core/utils/logger.dart';
import 'i_repo_firestore.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

// Import your enum
// import 'package:suefery/data/enums/query_operator.dart'; 

class RepoFirestore with LogMixin implements IRepoFirestore {
  final FirebaseFirestore _firestore;
  
  /// The [FirebaseFirestore] instance is injected.
  /// This allows for easy testing and emulator configuration.
  RepoFirestore._({required FirebaseFirestore firestore})  : _firestore = firestore;
  /// Creates and initializes a new [RepoFirestore] instance.
  ///
  /// If [useEmulator] is true, it will connect to the local
  /// Firebase Auth emulator on localhost:9099.
  ///
  /// Note: Emulators should only be used in debug builds.
  factory RepoFirestore.create({bool useEmulator = false}) {
    final instance = FirebaseFirestore.instance;
    final log = Logger('RepoFirestore.create');
    // Check for a Dart-defined environment variable to decide on using the emulator.

    // Use emulator only in debug mode and if requested
    if (kDebugMode && useEmulator) {
      try {
        log.info('Connecting to Firebase FirebaseFirestore Emulator...');
        final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)?  dotenv.get('local_device_ip'): 'localhost';
        instance.useFirestoreEmulator(emulatorHost, 8080);
        log.info('Connected to FirebaseFirestore Emulator on localhost:8080');
      } catch (e) {
        log.shout('*** FAILED TO CONNECT TO FirebaseFirestore EMULATOR: $e ***');
        log.shout(
            '*** Make sure the emulator is running: firebase emulators:start ***');
      }
    }
        // Enable offline persistence for better performance, especially on mobile
    if (!kIsWeb) {
      instance.settings = const Settings(persistenceEnabled: true);
    }
    return RepoFirestore._(
      firestore: instance,
    );
  }

  @override
  Future<String> generateId(String path,{String? id,int? timeOut}) async {
    DocumentReference<Map<String, dynamic>> ref;
    if (id == null) {
      ref = _firestore.collection(path).doc();
    }else{
      ref = _firestore.collection(path).doc(id);
    }
    await ref.set({});
    return ref.id;
  }

  @override
  Future<List<DocumentSnapshot<T>>> getCollection<T>(
    String collectionPath, {
    List<QueryCondition>? where,
    List<OrderBy>? orderBy,
    int? limit,
    int? timeOut
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    // Apply where clauses
    if (where != null) {
      for (var condition in where) {
        if (condition.isEqualTo != null) {
          query = query.where(condition.field, isEqualTo: condition.isEqualTo);
        } else if (condition.isLessThan != null) {
          query = query.where(condition.field, isLessThan: condition.isLessThan);
        } else if (condition.isLessThanOrEqualTo != null) {
          query = query.where(condition.field, isLessThanOrEqualTo: condition.isLessThanOrEqualTo);
        } else if (condition.isGreaterThan != null) {
          query = query.where(condition.field, isGreaterThan: condition.isGreaterThan);
        } else if (condition.isGreaterThanOrEqualTo != null) {
          query = query.where(condition.field, isGreaterThanOrEqualTo: condition.isGreaterThanOrEqualTo);
        } else if (condition.arrayContains != null) {
          query = query.where(condition.field, arrayContains: condition.arrayContains);
        } else if (condition.arrayContainsAny != null) {
          query = query.where(condition.field, arrayContainsAny: condition.arrayContainsAny);
        } else if (condition.whereIn != null) {
          query = query.where(condition.field, whereIn: condition.whereIn);
        } else if (condition.isNull != null) {
          query = query.where(condition.field, isNull: condition.isNull);
        }
      }
    }

    // Apply orderBy clauses
    if (orderBy != null) {
      for (var order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Apply limit clause
    if (limit != null) {
      query = query.limit(limit);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs as List<DocumentSnapshot<T>>;
  }
  
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream(
    String collectionPath, {
    List<QueryCondition>? where,  
    List<OrderBy>? orderBy,
    int? limit,
    int? timeOut
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    // Apply where clauses
    if (where != null) {
      for (var condition in where) {
        if (condition.isEqualTo != null) {
          query = query.where(condition.field, isEqualTo: condition.isEqualTo);
        } else if (condition.isLessThan != null) {
          query = query.where(condition.field, isLessThan: condition.isLessThan);
        } else if (condition.isLessThanOrEqualTo != null) {
          query = query.where(condition.field, isLessThanOrEqualTo: condition.isLessThanOrEqualTo);
        } else if (condition.isGreaterThan != null) {
          query = query.where(condition.field, isGreaterThan: condition.isGreaterThan);
        } else if (condition.isGreaterThanOrEqualTo != null) {
          query = query.where(condition.field, isGreaterThanOrEqualTo: condition.isGreaterThanOrEqualTo);
        } else if (condition.arrayContains != null) {
          query = query.where(condition.field, arrayContains: condition.arrayContains);
        } else if (condition.arrayContainsAny != null) {
          query = query.where(condition.field, arrayContainsAny: condition.arrayContainsAny);
        } else if (condition.whereIn != null) {
          query = query.where(condition.field, whereIn: condition.whereIn);
        } else if (condition.isNull != null) {
          query = query.where(condition.field, isNull: condition.isNull);
        }
      }
    }

    // Apply orderBy clauses
    if (orderBy != null) {
      for (var order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Apply limit clause
    if (limit != null) {
      query = query.limit(limit);
    }
    final stream = query.snapshots();
    
    return stream;
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentSnapShot(
      String collectionPath, String docId,{int? timeOut}) async {
    return await _firestore.collection(collectionPath).doc(docId).get();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDocumentStream(
      String collectionPath, String docId,{int? timeOut}) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }

  @override
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data,{String? id,int? timeOut}) async {
    if(id.isNotNullOrEmpty) {
      data['id'] = id;
      await _firestore.collection(collectionPath).doc(id).set(data);
    }else{
      data['id'] = _firestore.collection(collectionPath).doc().id;
      await _firestore.collection(collectionPath).doc(data['id']).set(data);
    }
  }
  
  @override
  Future<void> addMultipleDocument(String path, List<Map<String, dynamic>> data,{int? timeOut}) async {
    final batch = _firestore.batch();
    final collectionRef = _firestore.collection(path);
    for (var item in data) {
      final docRef = collectionRef.doc();
      item['id'] = docRef.id;
      batch.set(docRef, item);
    }
    try {
      await batch.commit().withTimeout();
      logInfo('Multiple documents created successfully!');
    } catch (e) {
      logError('Error creating multiple documents: $e');
      rethrow;
    }
  }

  @override
  Future<void> set(String path, String id, Map<String, dynamic> data,{int? timeOut}) async {
    try {
      final ref = _firestore.collection(path).doc(id);
      await ref.set(data).withTimeout();
    } catch (e) {
      logError("Error setting document in $path with ID $id: $e");
      rethrow;
    }
  }

  @override
  Future<void> batchSet(String path, List<Map<String, dynamic>> data,{int? timeOut}) async {
    try {
      final batch = _firestore.batch();
      for (var dataItem in data) {
        // Ensure the item has an ID.
        if (dataItem['id'] == null || (dataItem['id'] as String).isEmpty) {
          logWarning('Skipping item in batch set due to missing ID: $dataItem');
          continue;
        }
        final docId = dataItem['id'] as String;
        final docRef = _firestore.collection(path).doc(docId);
        batch.set(docRef, dataItem);
      }
      await batch.commit();
      logInfo('Batch set operation completed successfully for $path.');
    } catch (e) {
      logError("Error during batch set for path $path: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data,{int? timeOut}) async {
    await _firestore.collection(collectionPath).doc(documentId).update(data);
  }

  @override
  Future<void> setDocument(
      String collectionPath, String documentId, Map<String, dynamic> data , {bool merge = false,int? timeOut}) async {
    await _firestore.collection(collectionPath).doc(documentId).set(data);
  }
  @override
  Future<void> remove(String path, String id,{int? timeOut}) async {
    try {
      await _firestore.collection(path).doc(id).delete();
    } catch (e) {
      logError("Error removing document in $path with ID $id: $e");
      rethrow;
    }
  }

}