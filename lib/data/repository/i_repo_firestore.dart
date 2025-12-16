import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a condition for filtering documents in a Firestore query.
class QueryCondition {
  final String field;
  final dynamic isEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final bool? isNull;

  const QueryCondition(
    this.field, {
    this.isEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.isNull,
  });
}

/// Represents an ordering clause for documents in a Firestore query.
class OrderBy {
  final String field;
  final bool descending;

  const OrderBy(this.field, {this.descending = false});
}

/// An abstract interface for interacting with Firestore.
/// This allows for easy mocking and swapping of Firestore implementations.
abstract class IRepoFirestore {

  Future<String> generateId(String path,{String? id,int? timeOut}) ;

  /// Fetches a collection of documents from Firestore.
  ///
  /// [collectionPath] The path to the collection.
  /// [where] Optional list of [QueryCondition] to filter documents.
  /// [orderBy] Optional list of [OrderBy] to sort documents.
  /// Returns a list of [DocumentSnapshot] representing the documents.
  Future<List<DocumentSnapshot<T>>>? getCollection<T>(
    String collectionPath, {
    List<QueryCondition>? where,
    List<OrderBy>? orderBy,
    int? limit,
    int? timeOut
  });
  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream(
    String collectionPath, {
    List<QueryCondition>? where,  
    List<OrderBy>? orderBy,
    int? limit,
    int? timeOut
  });
  /// Updates a specific document in a collection.
  
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDocumentStream(String collectionPath, String docId,{int? timeOut});

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentSnapShot(String collectionPath, String docId,{int? timeOut});
  
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data,{String? id,int? timeOut}) ;

  Future<void> addMultipleDocument(String path, List<Map<String, dynamic>> data,{int? timeOut});

  /// Updates an existing document at the specified path and ID.
  Future<void> set(String path, String id, Map<String, dynamic> data,{int? timeOut});

  /// Updates batch of docs.
  Future<void> batchSet(String path,List<Map<String, dynamic>> data,{int? timeOut});

  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data,{int? timeOut});

  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data, {bool merge = false,int? timeOut});

  Future<void> remove(String path, String id,{int? timeOut});

}

