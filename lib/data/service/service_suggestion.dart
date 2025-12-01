import 'package:cloud_firestore/cloud_firestore.dart';
import '../enum/suggestion_type.dart';
import '../model/model_suggestion.dart';

class ServiceSuggestion {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded categories for fast access
  final List<ModelSuggestion> _categories =  [
    ModelSuggestion(title: "Dairy", type: SuggestionType.category, subtitle: "Milk, Cheese, Yogurt"),
    ModelSuggestion(title: "Snacks", type: SuggestionType.category, subtitle: "Chips, Chocolate"),
    ModelSuggestion(title: "Vegetables", type: SuggestionType.category, subtitle: "Fresh produce"),
    ModelSuggestion(title: "Fruits", type: SuggestionType.category, subtitle: "Fresh fruits"),
    ModelSuggestion(title: "Help", type: SuggestionType.command, subtitle: "Contact support"),
  ];

  Future<List<ModelSuggestion>> getMixedSuggestions(String query) async {
    if (query.isEmpty) return [];
    final normalized = query.toLowerCase();
    List<ModelSuggestion> results = [];

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
        return ModelSuggestion(
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