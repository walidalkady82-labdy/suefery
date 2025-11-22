import 'dart:async';
import 'package:suefery/data/models/order_model.dart';
import 'package:suefery/data/enums/order_status.dart';

import '../models/ai_parsed_order.dart';
import '../repositories/repo_log.dart';
import '../enums/query_operator.dart';
import '../repositories/i_repo_firestore.dart';
import 'remote_config_service.dart'; // Assuming path

class OrderService {
  final IRepoFirestore _firestoreRepo;
  final RemoteConfigService _configService;
  final _log = RepoLog('OrderService');
  final String _collectionPath = 'orders'; 

  OrderService(this._firestoreRepo, this._configService);

  /// Exposes the repository's ID generation method.
  String generateId() => _firestoreRepo.generateId(_collectionPath);

  /// Gets a stream of a single order, converting it to an [OrderModel].
  Stream<OrderModel?> getOrderStream(String orderId) {
    _log.i('Subscribing to order: $orderId');
    return _firestoreRepo
        .quaryDocumentStream(_collectionPath, orderId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        _log.w('Order $orderId does not exist.');
        return null;
      }
      return OrderModel.fromMap(snapshot.data()!);
    });
  }
  /// Gets a stream of all orders for a specific customer.
  Stream<List<OrderModel>> getOrdersForUser(String userId) {
    _log.i('Getting orders for user: $userId');
    return _firestoreRepo
        .quaryCollection(
          _collectionPath,
          'userId', 
          userId,
          quaryOperator: QueryComparisonOperator.eq,
          orderBy: 'createdAt',
          isDescending: true,
        )
        .asStream()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    });
  }
  /// Gets a stream of all orders for a specific rider.
  Stream<List<OrderModel>> getOrdersForRider(String riderId) {
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
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    });
  }
  /// Creates a new [OrderModel] from an [AiParsedOrder].
  Future<OrderModel> createOrder(AiParsedOrder aiOrder,
      {required String customerId, required String customerName}) async {
    _log.i('Converting AI order for customer: $customerId');

    // 1. Generate the new custom order ID (keeping your logic)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    // ... (rest of your newOrderId logic) ...
    final newOrderId = '...'; // Your logic here

    // 2. Get business rules from Remote Config
    final deliveryFee = _configService.deliveryFee;
    double estimatedTotal = 0.0;

    // 3. Convert AiParsedItem (DTO) to OrderItem (DB Model)
    final List<OrderItem> orderItems = aiOrder.requestedItems.map((aiItem) {
      //estimatedTotal += (aiItem.unitPrice * aiItem.quantity);
      return OrderItem(
        id: '', // Placeholder, you'd look this up
        name: aiItem.itemName,
        brand: aiItem.brand ?? 'unknown',
        unit: aiItem.unit ?? "EA",
        quantity: aiItem.quantity, 
        unitPrice: 0,
      );
    }).toList();

    // 4. Build the full OrderModel
    final newOrder = OrderModel(
      id: newOrderId,
      userId: customerId,
      partnerId: null,
      estimatedTotal: estimatedTotal,
      deliveryFee: deliveryFee,
      deliveryAddress: "strings.toBeConfirmed", // Placeholder
      status: OrderStatus.confirmed,
      items: orderItems,
      createdAt: DateTime.now(),
    );

    // 5. Use the repo to save the new order
    try {
      await _firestoreRepo.add( _collectionPath, newOrder.toMap() ,id: newOrderId);
      _log.i('Successfully created order: $newOrderId');
      return newOrder;
    } catch (e) {
      _log.e('Failed to save new order: $e');
      rethrow;
    }
  }
  /// Creates a new "draft" order from an AI-parsed order.
  /// This order has no price and is awaiting a quote from a partner.
  Future<OrderModel> createDraftOrder(AiParsedOrder aiOrder,
      {required String customerId, required String customerName}) async {
    _log.i('Creating draft order for customer: $customerId');

    // 1. Generate a unique ID for the draft.
    final newOrderId = generateId();

    // 2. Convert AiParsedItem to OrderItem (price will be 0.0)
    final List<OrderItem> orderItems = aiOrder.requestedItems.map((aiItem) {
      return OrderItem(
        id: '', // No product ID at this stage
        name: aiItem.itemName,
        brand: aiItem.brand ?? 'unknown',
        unit: aiItem.unit ?? "EA",
        quantity: aiItem.quantity,
        unitPrice: 0.0, // Price is unknown in a draft
      );
    }).toList();

    // 3. Build the OrderModel with a 'draft' status
    final newOrder = OrderModel(
      id: newOrderId,
      userId: customerId,
      estimatedTotal: 0.0, // No total for a draft
      deliveryFee: 0.0, // No fee for a draft
      deliveryAddress: 'To be confirmed',
      status: OrderStatus.draft, // <-- Key difference
      items: orderItems,
      createdAt: DateTime.now(),
    );

    // 4. Save the new draft order to Firestore
    try {
      await _firestoreRepo.add(_collectionPath, newOrder.toMap(), id: newOrderId);
      _log.i('Successfully created draft order: $newOrderId');
      return newOrder;
    } catch (e) {
      _log.e('Failed to save new draft order: $e');
      rethrow;
    }
  }
  /// Updates an existing order with new data.
  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    _log.i('Updating order: $orderId');
    try {
      // We use 'update' here to merge fields, not overwrite the document.
      await _firestoreRepo.update(_collectionPath, orderId, data);
      _log.i('Successfully updated order: $orderId');
    } catch (e) {
      _log.e('Failed to update order: $e');
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
  /// Called by the CLIENT App after user reviews the quote and pays successfully.
  Future<void> confirmOrderPayment(String orderId) async {
    _log.i('User paid. Confirming order: $orderId');
    await _firestoreRepo.update(_collectionPath, orderId, {
      'status': OrderStatus.confirmed.name,
      // You might also save a 'paymentReferenceId' here
    });
  }
  /// Assigns an order to a specific rider.
  Future<void> assignRider(String orderId, String riderId) {
    _log.i('Assigning order $orderId to rider $riderId');
    return _firestoreRepo.update(_collectionPath, orderId, {
      'riderId': riderId,
      'status': OrderStatus.assigned.name, // Business logic!
    });
  }
  
}