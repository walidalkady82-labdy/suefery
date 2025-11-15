import 'package:equatable/equatable.dart';

class PromotionModel extends Equatable {
  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.promoCode,
    this.imageUrl,
    this.expiryDate,
  });

  final String id;
  final String title;
  final String description;
  final String promoCode;
  final String? imageUrl;
  final DateTime? expiryDate;

  @override
  List<Object?> get props =>
      [id, title, description, promoCode, imageUrl, expiryDate];
}