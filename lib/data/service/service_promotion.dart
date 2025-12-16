import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suefery/core/utils/logger.dart';
import '../model/model_promotion.dart';
import '../../presentation/widgets/chat/models/chat_item.dart';
import '../enum/promotion_type.dart';

class ServicePromotion with LogMixin{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// TRIGGER 1: CONTEXTUAL (Item Specific)
  /// Call this when the AI detects an intent to buy a specific item (e.g., "Burger").
  /// Returns a list of active promotions for that item.
  Future<List<PromotionItem>> findPromotionsForItem(String itemName) async {
    try {
      // Logic: Search 'promotions' where the 'eligibleItems' array contains this item.
      // Note: Ensure your Firestore collection is named 'promotions'.
      final snapshot = await _firestore
          .collection('promotions')
          .where('type', isEqualTo: 'item_specific')
          .where('eligibleItems', arrayContains: itemName) // Requires Exact Match
          .where('isActive', isEqualTo: true)
          .get();

      // Convert Database Models -> UI Chat Bubbles
      return snapshot.docs
          .map((doc) => ModelPromotion.fromFirestore(doc.data(), doc.id).toChatItem())
          .toList();
    } catch (e) {
      logError("Error fetching item promos: $e");
      return [];
    }
  }

  /// TRIGGER 2: MILESTONE (Loyalty)
  /// Call this when the Chat initializes or Order is completed.
  /// Checks if the user qualifies for a generic loyalty reward.
  Future<PromotionItem?> checkLoyaltyMilestone(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final int orderCount = data['orderCount'] ?? 0;
      final bool hasReceivedGold = data['hasReceivedGoldReward'] ?? false;

      // Logic: If user has 10+ orders and hasn't received the reward yet
      if (orderCount >= 10 && !hasReceivedGold) {
        // We construct this dynamically or fetch it from a 'rewards' collection
        return const PromotionItem(
          id: 'loyalty_gold_10',
          title: 'Gold Status Unlocked! 🏆',
          description: 'You have placed 10 orders. Enjoy free delivery on your next order.',
          promoCode: 'GOLDMEMBER',
          type: PromotionType.customerSpecific, // Triggers Gold Styling
        );
      }
      return null;
    } catch (e) {
      logError("Error checking loyalty: $e");
      return null;
    }
  }

  /// TRIGGER 3: EXPLICIT QUERY
  /// Call this when user asks "Do you have any offers?"
  Future<List<PromotionItem>> getGeneralOffers() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('isGeneral', isEqualTo: true) // Public offers
          .limit(3)
          .get();

      return snapshot.docs
          .map((doc) => ModelPromotion.fromFirestore(doc.data(), doc.id).toChatItem())
          .toList();
    } catch (e) {
      return [];
    }
  }
}