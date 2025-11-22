import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_model.dart';

class BrandService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches brand suggestions starting with [query].
  Future<List<BrandModel>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase();

    // Firestore "Start At" query for prefix search
    final snapshot = await _firestore
        .collection('brands')
        .orderBy('searchKey')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff']) // \uf8ff is a high unicode char
        .limit(10) // Limit results for performance
        .get();

    return snapshot.docs.map((doc) => BrandModel.fromMap(doc.data())).toList();
  }
}