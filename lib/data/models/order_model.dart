import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:suefery/data/enums/order_status.dart';

/// The main model for an order saved in the database.
/// This replaces `StructuredOrder`.
class OrderModel extends Equatable {
  final String id; // Was 'orderId'
  final String userId; // Was 'customerId'
  final String? riderId;
  final double estimatedTotal;
  final double deliveryFee;
  final String deliveryAddress;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? finishedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    this.riderId,
    required this.estimatedTotal,
    required this.deliveryFee,
    required this.deliveryAddress,
    required this.status,
    required this.items,
    required this.createdAt,
    this.finishedAt,
  });

  @override
  List<Object?> get props => [id, userId, riderId, status, items, createdAt];

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      riderId: map['riderId'] as String?,
      estimatedTotal: (map['estimatedTotal'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num).toDouble(),
      deliveryAddress: map['deliveryAddress'] as String,
      status: OrderStatus.values
          .firstWhere((e) => e.name == map['status'], orElse: () => OrderStatus.pending),
      items: (map['items'] as List)
          .map((itemMap) => OrderItem.fromMap(itemMap))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      finishedAt: (map['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'riderId': riderId,
      'estimatedTotal': estimatedTotal,
      'deliveryFee': deliveryFee,
      'deliveryAddress': deliveryAddress,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
    };
  }
}

/// An item within a confirmed [OrderModel].
class OrderItem extends Equatable {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? notes;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [id, name, quantity,unit , unitPrice, notes];

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['productId'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  OrderItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? notes,
  }) {
      return OrderItem(
        id: this.id,
        name: this.name,
        quantity: this.quantity,
        unit: this.unit,
        unitPrice: this.unitPrice,
        notes: this.notes,
      );
    }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'notes': notes,
    };
  }
}