  import 'package:suefery/models/order.status.dart';

class OrderModel {
    final int orderId;
    final String customerId;
    final String storeName;
    final double estimatedTotal;
    final String deliveryAddress;
    final OrderStatus status;
    final double progress; // 0.0 to 1.0 for tracking
    final List<Map<String, dynamic>> items;
    final String? riderId;

    OrderModel({
      required this.orderId,
      required this.customerId,
      required this.storeName,
      required this.estimatedTotal,
      required this.deliveryAddress,
      required this.status,
      this.progress = 0.0,
      required this.items,
      this.riderId,
    });

    factory OrderModel.fromMap(Map<String, dynamic> data) {
      // Safely map data from Firestore document
      return OrderModel(
        orderId: data['orderId'] as int,
        customerId: data['customerId'] as String,
        storeName: data['storeName'] as String,
        estimatedTotal: (data['estimatedTotal'] as num).toDouble(),
        deliveryAddress: data['deliveryAddress'] as String,
        // Convert string status back to enum
        status: OrderStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => OrderStatus.New,
        ),
        progress: (data['progress'] as num).toDouble(),
        // Ensure items is a List<Map<String, dynamic>>
        items: (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
        riderId: data['riderId'] as String?,
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'orderId': orderId,
        'customerId': customerId,
        'storeName': storeName,
        'estimatedTotal': estimatedTotal,
        'deliveryAddress': deliveryAddress,
        'status': status.name,
        'progress': progress,
        'items': items,
        'riderId': riderId,
      };
    }

    // Simplified copyWith for BLoC state updates
    OrderModel copyWith({
      OrderStatus? status,
      double? progress,
      String? riderId,
    }) {
      return OrderModel(
        orderId: orderId,
        customerId: customerId,
        storeName: storeName,
        estimatedTotal: estimatedTotal,
        deliveryAddress: deliveryAddress,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        items: items,
        riderId: riderId ?? this.riderId,
      );
    }
  }