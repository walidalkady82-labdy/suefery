import 'package:equatable/equatable.dart';
import '../../presentation/widgets/chat/models/chat_item.dart';
import '../enum/promotion_type.dart'; // Import for the Enum and ChatItem

class ModelPromotion extends Equatable {
  const ModelPromotion({
    required this.id,
    required this.title,
    required this.description,
    this.promoCode,
    required this.promotionType,
    this.imageUrl,
    this.expiryDate,
    this.eligibleItems = const [], // <--- Added to support item-specific deals
  });

  final String id;
  final String title;
  final String description;
  final String? promoCode;
  
  // Ideally, move PromotionType to 'lib/data/enums/' so both files can share it.
  // For now, we use the one defined in chat_item.dart or a matching local enum.
  final PromotionType promotionType; 
  
  final String? imageUrl;
  final DateTime? expiryDate;
  
  // List of product names this promo applies to
  final List<String> eligibleItems; 

  @override
  List<Object?> get props => [
    id, title, description, promotionType, promoCode, imageUrl, expiryDate, eligibleItems
  ];

  /// --- MAPPER ---
  /// Converts this database model into a UI Chat Bubble
  PromotionItem toChatItem() {
    return PromotionItem(
      id: id,
      title: title,
      description: description,
      // UI requires a string, handle null case or 'Auto-Applied'
      promoCode: promoCode ?? 'AUTO-APPLY', 
      imageUrl: imageUrl,
      type: promotionType,
      eligibleItems: eligibleItems,
    );
  }

  // Optional: Factory to create from Firestore
  factory ModelPromotion.fromFirestore(Map<String, dynamic> data, String id) {
    return ModelPromotion(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      promoCode: data['promoCode'],
      promotionType: _parseType(data['type']),
      imageUrl: data['imageUrl'],
      expiryDate: data['expiryDate'] != null 
          ? (data['expiryDate'] as dynamic).toDate() 
          : null,
      eligibleItems: List<String>.from(data['eligibleItems'] ?? []),
    );
  }

  static PromotionType _parseType(String? type) {
    if (type == 'item_specific') return PromotionType.itemSpecific;
    return PromotionType.customerSpecific;
  }
}