import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:suefery/data/enum/order_item_status.dart';
import 'package:suefery/data/enum/order_status.dart';

/// The main model for an order saved in the database.
/// This replaces `StructuredOrder`.
class ModelOrder extends Equatable {
  final String id; // Was 'orderId'
  final String description;
  final String userId; // Was 'customerId'
  final String? partnerId;
  final String? riderId;
  final double estimatedTotal;
  final double deliveryFee;
  final String deliveryAddress;
  final OrderStatus status;
  final double progress; // Value from 0.0 to 1.0
  final List<ModelOrderItem> items;
  final DateTime createdAt;
  final DateTime? finishedAt;

  const ModelOrder({
    required this.id,
    required this.description,
    required this.userId,
    this.partnerId,
    this.riderId,
    required this.estimatedTotal,
    required this.deliveryFee,
    required this.deliveryAddress,
    required this.status,
    this.progress = 0.0,
    required this.items,
    required this.createdAt,
    this.finishedAt,
  });

  @override
  List<Object?> get props => [id, description, userId, partnerId, riderId, status, progress, items, createdAt];

  factory ModelOrder.fromMap(Map<String, dynamic> map) {
    return ModelOrder(
      id: map['id'] as String,
      description: map['description'] as String,
      userId: map['userId'] as String,
      partnerId: map['partnerId'] as String?,
      riderId: map['riderId'] as String?,
      estimatedTotal: (map['estimatedTotal'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num).toDouble(),
      deliveryAddress: map['deliveryAddress'] as String,
      status: OrderStatus.values
          .firstWhere((e) => e.name == map['status'], orElse: () => OrderStatus.draft),
      progress: (map['progress'] as num? ?? 0.0).toDouble(),
      items: (map['items'] as List)
          .map((itemMap) => ModelOrderItem.fromMap(itemMap))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      finishedAt: (map['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  ModelOrder copyWith({
  String? id,
  String? description,
  String? userId,
  String? partnerId,
  String? riderId,
  double? estimatedTotal,
  double? deliveryFee,
  String? deliveryAddress,
  OrderStatus? status,
  double? progress, // Value from 0.0 to 1.0
  List<ModelOrderItem>? items,
  DateTime? createdAt,
  DateTime? finishedAt


  }) {
    return ModelOrder(
      id: id ?? this.id,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      riderId: riderId ?? this.riderId,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'userId': userId,
      'partnerId': partnerId,
      'riderId': riderId,
      'estimatedTotal': estimatedTotal,
      'deliveryFee': deliveryFee,
      'deliveryAddress': deliveryAddress,
      'status': status.name,
      'progress': progress,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
    };
  }
}

/// An item within a confirmed [ModelOrder].
class ModelOrderItem extends Equatable {
  final String id;
  final String description;
  final String brand;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? notes;
  final OrderItemStatus itemStatus;
  final String? partnerNotes;

  const ModelOrderItem({
    required this.id,
    required this.description,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.notes,
    this.itemStatus = OrderItemStatus.available,
    this.partnerNotes,
  });

  @override
  List<Object?> get props => [id, description, quantity,unit , unitPrice, notes, itemStatus, partnerNotes];

  factory ModelOrderItem.fromMap(Map<String, dynamic> map) {
    return ModelOrderItem(
      id: map['id'] as String,
      description: map['description'] as String,
      brand: map['brand'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      notes: map['notes'] as String?,
      itemStatus: OrderItemStatus.values
          .firstWhere((e) => e.name == map['itemStatus'], orElse: () => OrderItemStatus.available),
      partnerNotes: map['partnerNotes'] as String?,
    );
  }

  ModelOrderItem copyWith({
    String? id,
    String? description,
    String? brand,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? notes,
    OrderItemStatus? itemStatus,
    String? partnerNotes,
  }) {
      return ModelOrderItem(
        id: id ?? this.id,
        description: description ?? this.description,
        brand: brand ?? this.brand,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
        notes: notes ?? this.notes,
        itemStatus: itemStatus ?? this.itemStatus,
        partnerNotes: partnerNotes ?? this.partnerNotes,
      );
    }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'notes': notes,
      'itemStatus': itemStatus.name,
      'partnerNotes': partnerNotes,
    };
  }
}