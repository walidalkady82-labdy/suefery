import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/enums/order_status.dart';

import '../../domain/repositories/log_repo.dart';
import '../enums/query_operator.dart';
import '../repositories/i_firestore_repository.dart'; // Assuming path

class OrderService {
  final IFirestoreRepo _firestoreRepo;
  final _log = LogRepo('OrderService');
  final String _collectionPath = 'orders'; // Business logic!

  OrderService(this._firestoreRepo);

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

  /// Generate order id
  Future<String> generateOrderId() async {
    try {
      _log.i('Creating new order id');
      // getting id
      return _firestoreRepo.generateId('orders');
          
    } catch (e) {
      _log.e('Failed to create id: $e');
      rethrow;
    }
  }

  /// Creates a new order in the database.
  Future<String> createOrder(StructuredOrder order) {
    try {
      _log.i('Creating new order for customer: ${order.customerId}');
      // Business Logic: Convert model to a map to be stored
      final data = order.toMap();
      // Use the 'add' method to let Firestore generate the ID
      // *Wait, our model requires an ID. Let's adjust.*
      
      // Let's assume the ID is passed in from the model
      if (order.orderId.isEmpty) {
         _log.e('Order ID cannot be empty for creation.');
         throw Exception('Order ID is required to create order.');
      }
      
      // Use 'update' (which acts as 'set' on a new doc)
      // to ensure the ID is what we passed in.
      return _firestoreRepo
          .update(_collectionPath, order.orderId, data)
          .then((_) => order.orderId);
          
    } catch (e) {
      _log.e('Failed to create order: $e');
      rethrow;
    }
  }

  /// Updates the status of an existing order.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    _log.i('Updating order $orderId to status ${newStatus.name}');
    // Business Logic: Only update a single field
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
  
  /// Deletes an order from the database.
  Future<void> deleteOrder(String orderId) {
    _log.w('Deleting order: $orderId');
    return _firestoreRepo.remove(_collectionPath, orderId);
  }
}