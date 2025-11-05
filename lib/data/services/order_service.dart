import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/order_item.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/enums/order_status.dart';

import '../../domain/repositories/log_repo.dart';
import '../enums/query_operator.dart';
import '../repositories/i_firestore_repository.dart';
import 'remote_config_service.dart'; // Assuming path

class OrderService {
  final IFirestoreRepo _firestoreRepo;
  final RemoteConfigService _configService;
  final _log = LogRepo('OrderService');
  final String _collectionPath = 'orders'; // Business logic!

  OrderService(this._firestoreRepo, this._configService);

  /// Gets a stream of a single order, converting it to a [StructuredOrder].
  Stream<StructuredOrder?> getOrderStream(String orderId) {
    _log.i('Subscribing to order: $orderId');
    return _firestoreRepo
        .quaryDocumentStream(_collectionPath, orderId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        _log.w('Order $orderId does not exist.');
        return null;
      }
      // Business Logic: Convert raw map to a structured model
      return StructuredOrder.fromMap(snapshot.data()!);
    });
  }
  ///Gets a stream of all PENDING orders for a specific customer.
  Stream<List<StructuredOrder>> getPendingOrdersStream(String userId) {
    _log.i('Getting PENDING orders for user: $userId');
    
    // We create a filter for 'Pending' and 'Assigned' orders
    final filter = Filter.and(
      Filter('customerId', isEqualTo: userId),
      Filter('status', whereIn: [
        OrderStatus.New.name, 
        OrderStatus.Assigned.name
      ]),
    );

    return _firestoreRepo
        .queryWithFilter(
          _collectionPath,
          filter,
        )
        .asStream() // Convert Future to Stream
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StructuredOrder.fromMap(doc.data()))
          // Sort by date so newest is first
          .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
  /// Gets a stream of all orders for a specific customer.
  Stream<List<StructuredOrder>> getOrdersForUser(String userId) {
    _log.i('Getting orders for user: $userId');
    return _firestoreRepo
        .quaryCollection(
          _collectionPath,
          'customerId',
          userId,
          quaryOperator: QueryComparisonOperator.eq,
          orderBy: 'createdAt', // Business logic: Sort by date
          isDescending: true,
        )
        .asStream() // Convert Future to Stream for consistency (or keep as Future)
        .map((snapshot) {
      // Business Logic: Convert a list of documents
      return snapshot.docs
          .map((doc) => StructuredOrder.fromMap(doc.data()))
          .toList();
    });
  }
  
  /// Gets a stream of all orders for a specific rider.
  Stream<List<StructuredOrder>> getOrdersForRider(String riderId) {
    _log.i('Getting orders for rider: $riderId');
    // This uses the more complex quaryCollection method
    return _firestoreRepo
        .quaryCollection(
          _collectionPath,
          'riderId',
          riderId,
          quaryOperator: QueryComparisonOperator.eq,
          orderBy: 'createdAt', 
          isDescending: true,
        )
        .asStream()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StructuredOrder.fromMap(doc.data()))
          .toList();
    });
  }

  /// Creates a new [StructuredOrder] from an [AiParsedOrder].
  /// This method applies business rules (like delivery fee).
  Future<StructuredOrder> creatStructuredOrder(
      AiParsedOrder aiOrder, String customerId) async {
    _log.i('Converting AI order for customer: $customerId');

    // 1. Generate a new, unique ID for the order
    final newOrderId = _firestoreRepo.generateId(_collectionPath);

    // 2. Get business rules from Remote Config
    final deliveryFee = _configService.deliveryFee;
    double estimatedTotal = 0.0;

    // 3. Convert AI items to real OrderItems
    // In a real app, you would look up prices here
    final List<OrderItem> orderItems = aiOrder.requestedItems.map((aiItem) {
      const itemPrice = 0.0; // Placeholder price
      estimatedTotal += (itemPrice * aiItem.quantity);

      return OrderItem(
        itemId: '', // Placeholder
        name: aiItem.itemName,
        quantity: aiItem.quantity,
        unitPrice: itemPrice,
        notes: aiItem.notes,
      );
    }).toList();

    // 4. Build the full StructuredOrder
    final newOrder = StructuredOrder(
      orderId: newOrderId,
      customerId: customerId,
      riderId: null,
      estimatedTotal: estimatedTotal,
      deliveryFee: deliveryFee, // <-- USE THE CONFIG VALUE
      deliveryAddress: 'To be confirmed',
      status: OrderStatus.New,
      items: orderItems,
      createdAt: DateTime.now(), 
      partnerId: '', 
      progress: 0, 
      finishedAt: DateTime(1900),
      
    );

    // 5. Use the repo to save the new order
    try {
      await _firestoreRepo.update(
          _collectionPath, newOrderId, newOrder.toMap());
      _log.i('Successfully created order: $newOrderId');
      return newOrder; // Return the full order object
    } catch (e) {
      _log.e('Failed to save new order: $e');
      rethrow;
    }
  }

  /// Deletes an order from the database.
  Future<void> deleteOrder(String orderId) {
    _log.w('Deleting order: $orderId');
    return _firestoreRepo.remove(_collectionPath, orderId);
  }

  /// Updates the status of an existing order.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    _log.i('Updating order $orderId to status ${newStatus.name}');
    return _firestoreRepo.update(_collectionPath, orderId, {
      'status': newStatus.name,
    });
  }
  
  /// Assigns an order to a specific rider.
  Future<void> assignRider(String orderId, String riderId) {
    _log.i('Assigning order $orderId to rider $riderId');
    return _firestoreRepo.update(_collectionPath, orderId, {
      'riderId': riderId,
      'status': OrderStatus.Assigned.name, // Business logic!
    });
  }
  
}