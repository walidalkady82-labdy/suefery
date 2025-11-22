import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/suggestion_type.dart';
import '../models/suggestion_model.dart';

class SuggestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded categories for fast access
  final List<SuggestionModel> _categories = [
    SuggestionModel(title: "Dairy", type: SuggestionType.category, subtitle: "Milk, Cheese, Yogurt"),
    SuggestionModel(title: "Snacks", type: SuggestionType.category, subtitle: "Chips, Chocolate"),
    SuggestionModel(title: "Vegetables", type: SuggestionType.category, subtitle: "Fresh produce"),
    SuggestionModel(title: "Fruits", type: SuggestionType.category, subtitle: "Fresh fruits"),
    SuggestionModel(title: "Help", type: SuggestionType.command, subtitle: "Contact support"),
  ];

  Future<List<SuggestionModel>> getMixedSuggestions(String query) async {
    if (query.isEmpty) return [];
    final normalized = query.toLowerCase();
    List<SuggestionModel> results = [];

    // 1. SEARCH CATEGORIES (Local filter)
    results.addAll(_categories.where((c) => c.title.toLowerCase().contains(normalized)));

    // 2. SEARCH BRANDS (Firestore)
    // Only query if we don't have too many results yet
    if (results.length < 5) {
      final snapshot = await _firestore
          .collection('brands')
          .orderBy('searchKey')
          .startAt([normalized])
          .endAt(['$normalized\uf8ff'])
          .limit(5)
          .get();

      final brands = snapshot.docs.map((doc) {
        final data = doc.data();
        return SuggestionModel(
          title: data['name'],
          subtitle: data['category'], // e.g., "Dairy"
          type: SuggestionType.brand,
        );
      });
      results.addAll(brands);
    }

    return results;
  }
}