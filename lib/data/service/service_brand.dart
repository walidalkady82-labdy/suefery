import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suefery/core/extensions/future_extension.dart';
import '../model/model_brand.dart';

class ServiceBrand {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches brand suggestions starting with [query].
  Future<List<ModelBrand>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase();

    // Firestore "Start At" query for prefix search
    final snapshot = await _firestore
        .collection('brands')
        .orderBy('searchKey')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff']) // \uf8ff is a high unicode char
        .limit(10) // Limit results for performance
        .get().withTimeout();

    return snapshot.docs.map((doc) => ModelBrand.fromMap(doc.data())).toList();
  }
}