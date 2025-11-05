import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/query_operator.dart';



abstract class IFirestoreRepo {
  /// Generates a new unique document ID for a given collection path.
  String generateId(String path);

  /// Adds a new document (as a map) to the specified collection path.
  /// Returns the ID of the newly created document.
  Future<String> add(String path, Map<String, dynamic> data);

  /// Adds multiple documents in a single atomic batch operation.
  Future<void> addMultiple(String path, List<Map<String, dynamic>> data);

  /// Updates an existing document at the specified path and ID.
  Future<void> update(String path, String id, Map<String, dynamic> data);

  /// Updates an existing document at the specified path and ID.
  Future<void> set(String path, String id, Map<String, dynamic> data);

  /// Removes a document from the specified path and ID.
  Future<void> remove(String path, String id);

  /// Returns a stream of an entire collection.
  Stream<QuerySnapshot<Map<String, dynamic>>> quaryCollectionStream(
    String collectionPath, {
    String? orderBy,
    bool isDescending = false,
  });

  /// Performs a complex query on a collection.
  Future<QuerySnapshot<Map<String, dynamic>>> quaryCollection(
    String collection,
    dynamic field,
    dynamic queryValue, {
    QueryComparisonOperator? quaryOperator,
    String? orderBy,
    bool? isDescending,
  });

  /// Returns a stream of a single document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> quaryDocumentStream(
      String collectionPath, String docId);

  /// Fetches a single document snapshot one time.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentSnapShot(
      String collectionPath, String docId);

  /// Queries for the first document that matches a field and value.
  Future<QuerySnapshot<Map<String, dynamic>>> quarySnapshot(
    String collection,
    dynamic field,
    dynamic queryValue, {
    QueryComparisonOperator quaryOperator = QueryComparisonOperator.eq,
  });

  /// Queries a collection using a modern Firestore [Filter] object.
  Future<QuerySnapshot<Map<String, dynamic>>> queryWithFilter(
      String collectionPath, Filter queryFilter);

  
}