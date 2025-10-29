import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/enums/query_operator.dart';
import 'log_repo.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;

class FirestoreRepo {
  final _log = LogRepo('FirestoreRepository');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initEmulator() async {
    const emulatorPortDb = 8080;
    final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)? '10.0.2.2': 'localhost';
    if (defaultTargetPlatform != TargetPlatform.android && kDebugMode) {
      _firestore.useFirestoreEmulator(emulatorHost, emulatorPortDb);
    }
  }
  
  String generateId(String path) {
    final ref = _firestore.collection(path).doc();
    return ref.id;
  }

  Future<String> add(String path, Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection(path).doc();
      data['id'] = ref.id; // Add the ID to the data
      await ref.set(data); // Use set() for creating documents with generated IDs
      return ref.id;
    } catch (e) {
      _log.e("Error adding document to $path: $e");
      rethrow;
    }
  }

  Future<void> addMultiple(String path,List<Map<String, dynamic>> data) async {
    final batch = _firestore.batch();
    // Get a reference to the collection
    final collectionRef = _firestore.collection(path); // Replace 'your_collection_name'
    for (var item in data) {
      // Create a document reference with a generated ID
      final docRef = collectionRef.doc(); // Auto-generate document ID
      item['id'] = docRef.id;
      // Add the document data to the batch
      batch.set(docRef, item);
    }
    try {
      await batch.commit();
      _log.i('Multiple documents created successfully!');
    } catch (e) {
      _log.e('Error creating multiple documents: $e');
    }
  }

  Future<void> update(String path, String id, Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection(path).doc(id); // Direct document reference
      await ref.update(data);
    } catch (e) {
      _log.e("Error updating document in $path with ID $id: $e");
      rethrow;
    }
  }

  Future<void> remove(String path, String id) async {
    try {
      await _firestore.collection(path).doc(id).delete();
    } catch (e) {
      _log.e("Error removing document in $path with ID $id: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> quaryCollectionStream(String collectionPath){
    return _firestore.collection(collectionPath).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> quaryCollection(
      String collection, 
      dynamic field,
      dynamic queryValue,
      {QueryComparisonOperator? quaryOperator,String? orderBy,bool? isDescending} 
    ) async {
              QuerySnapshot<Map<String, dynamic>> querySnapshot;
              
              if(quaryOperator == null) {
                querySnapshot = await _firestore.collection(collection).get();
              }
              else {
                switch (quaryOperator) {
                  case QueryComparisonOperator.eq:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isEqualTo: queryValue).get();
                    break;
                  case QueryComparisonOperator.ne:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isNotEqualTo: queryValue).get();
                    break;
                  case QueryComparisonOperator.lt:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isLessThan: queryValue).get();
                    break;
                  case QueryComparisonOperator.lte:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isLessThanOrEqualTo: queryValue).get();
                    break;
                  case QueryComparisonOperator.gt:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isGreaterThan: queryValue).get();
                    break;
                  case QueryComparisonOperator.gte:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, isGreaterThanOrEqualTo: queryValue).get();
                    break;
                  case QueryComparisonOperator.cArr:
                    querySnapshot = await _firestore
                                  .collection(collection)
                                  .where(field, arrayContains: queryValue).get();
                    break;
                  case QueryComparisonOperator.cArrAny:
                    querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, arrayContainsAny: queryValue).get();
                    break;
                  case QueryComparisonOperator.inArr:
                    querySnapshot = await _firestore
                      .collection(collection)
                      .where(field, whereIn: queryValue).get();
                    break;
                  case QueryComparisonOperator.ninArr:
                    querySnapshot = await _firestore
                      .collection(collection)
                      .where(field, whereNotIn: queryValue).get();
                    break;
                  case QueryComparisonOperator.isNull:
                    querySnapshot = await _firestore
                      .collection(collection)
                      .where(field, isNull: queryValue).get();
                    break;
                }
              }
              return querySnapshot;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> quaryDocumentStream(String collectionPath,String docId){
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }
  
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentSnapShot(String collectionPath,String docId) async {
    return await _firestore.collection(collectionPath).doc(docId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> quarySnapshot(String collection, dynamic field,dynamic queryValue,{QueryComparisonOperator quaryOperator = QueryComparisonOperator.eq} ) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    switch (quaryOperator) {
        case QueryComparisonOperator.eq:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isEqualTo: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.ne:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isNotEqualTo: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.lt:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isLessThan: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.lte:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isLessThanOrEqualTo: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.gt:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isGreaterThan: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.gte:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, isGreaterThanOrEqualTo: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.cArr:
          querySnapshot = await _firestore
                        .collection(collection)
                        .where(field, arrayContains: queryValue)
                        .limit(1).get();
          break;
        case QueryComparisonOperator.cArrAny:
          querySnapshot = await _firestore
              .collection(collection)
              .where(field, arrayContainsAny: queryValue)
              .limit(1).get();
          break;
        case QueryComparisonOperator.inArr:
          querySnapshot = await _firestore
            .collection(collection)
            .where(field, whereIn: queryValue)
            .limit(1).get();
          break;
        case QueryComparisonOperator.ninArr:
          querySnapshot = await _firestore
            .collection(collection)
            .where(field, whereNotIn: queryValue)
            .limit(1).get();
          break;
        case QueryComparisonOperator.isNull:
          querySnapshot = await _firestore
            .collection(collection)
            .where(field, isNull: queryValue)
            .limit(1).get();
          break;
      }
    return querySnapshot;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryWithFilter(
    String collectionPath,
    Filter queryFilter
  ) async {
    return await _firestore.collection(collectionPath).where(
      queryFilter
    ).get();
  }

}
