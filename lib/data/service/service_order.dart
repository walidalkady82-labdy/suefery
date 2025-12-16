import 'dart:async';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/model/model_chat_message.dart';
import 'package:suefery/core/errors/database_exception.dart'; // Import DatabaseFailure
import 'package:suefery/data/model/model_order.dart';
import 'package:suefery/data/enum/order_status.dart';

import '../model/model_ai_parsed_order.dart';
import '../repository/i_repo_firestore.dart';
import 'service_remote_config.dart'; // Assuming path

class ServiceOrder with LogMixin{
  final IRepoFirestore _firestoreRepo;
  final ServiceRemoteConfig _configService;
  final String _collectionPath = 'orders'; 

  ServiceOrder(this._firestoreRepo, this._configService);

  /// Gets a stream of a single order, converting it to an [ModelOrder].
  Stream<ModelOrder?> getOrderStream(String orderId) {
    logInfo('Subscribing to order: $orderId');
    return _firestoreRepo
        .getDocumentStream(_collectionPath, orderId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        logWarning('Order $orderId does not exist.');
        return null;
      }
      return ModelOrder.fromMap(snapshot.data()!);
    });
  }
  ///Gets a snapshot of all orders for a specific customer.
  Future<List<ModelOrder>?> getOrdersForUser(
    String userId,
    {List<OrderStatus>? statuses}
  ) async {
    logInfo('Getting orders for user: $userId');
    final conditions = <QueryCondition>[
      QueryCondition('userId', isEqualTo: userId),
    ];

    if (statuses != null && statuses.isNotEmpty) {
      conditions.add(QueryCondition(
        'status',
        whereIn: statuses.map((s) => s.name).toList(),
      ));
    }
    
    return statuses== null
        ? await _firestoreRepo
        .getCollection(
          _collectionPath,
          where: [ 
            QueryCondition('userId',isEqualTo:userId) ,
          ],
          orderBy: [OrderBy('createdAt' , descending: false) , ]
        )?.then((snapshot) {
          return snapshot
              .map((doc) => ModelOrder.fromMap(doc.data()))
              .toList();
        }
        )
        :
        _firestoreRepo
        .getCollection(
          _collectionPath,
          where: conditions,
          orderBy: [OrderBy('createdAt' , descending: false) , ]
        )?.then((snapshot) {
          return snapshot
              .map((doc) => ModelOrder.fromMap(doc.data()))
              .toList();
        }
        );
  }
  /// Gets a stream of all orders for a specific customer.
  Stream<List<ModelOrder>> getOrdersForUserStream(
    String userId,
    {List<OrderStatus>? statuses}
  ) {
    logInfo('Getting orders for user: $userId');
    final conditions = <QueryCondition>[
      QueryCondition('userId', isEqualTo: userId),
    ];

    if (statuses != null && statuses.isNotEmpty) {
      conditions.add(QueryCondition(
        'status',
        whereIn: statuses.map((s) => s.name).toList(),
      ));
    }
    return statuses== null
        ? _firestoreRepo
        .getCollectionStream(
          _collectionPath,
          where: [ 
            QueryCondition('userId',isEqualTo:userId) ,
          ],
          orderBy: [OrderBy('createdAt' , descending: false) , ]
        ).map((snapshot) {
          return snapshot.docs
              .map((doc) => ModelOrder.fromMap(doc.data()))
              .toList();
        })
        :
        _firestoreRepo
        .getCollectionStream(
          _collectionPath,
          where: conditions,
          orderBy: [OrderBy('createdAt' , descending: false) , ]
        ).map((snapshot) {
          return snapshot.docs
              .map((doc) => ModelOrder.fromMap(doc.data()))
              .toList();
        });
  }
  /// Gets a stream of all orders for a specific rider.
  Stream<List<ModelOrder>> getOrdersForRider(String riderId) {
    logInfo('Getting orders for rider: $riderId');
    // This uses the more complex quaryCollection method
    return _firestoreRepo.
        getCollectionStream(
          _collectionPath,
          where: [ QueryCondition('riderId',isEqualTo:riderId) ],
          orderBy: [OrderBy('createdAt' , descending: false) , ]
        ).map((snapshot) {
          return snapshot.docs
              .map((doc) => ModelOrder.fromMap(doc.data()))
              .toList();
        });
  }
  /// Creates a new [ModelOrder] from an [ModelAiParsedOrder].
  Future<ModelOrder> createOrder(ModelAiParsedOrder aiOrder,
      {required String customerId, required String customerName}) async {
    logInfo('Converting AI order for customer: $customerId');

    // 1. Generate the new custom order ID (keeping your logic)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final newOrderId = '$customerId-${startOfDay.millisecondsSinceEpoch}';
    // 2. Get business rules from Remote Config
    final deliveryFee = _configService.deliveryFee;
    double estimatedTotal = 0.0;

    // 3. Convert AiParsedItem (DTO) to OrderItem (DB Model)
    final List<ModelOrderItem> orderItems = aiOrder.requestedItems.map((aiItem) {
      //estimatedTotal += (aiItem.unitPrice * aiItem.quantity);

      return ModelOrderItem(
        id:newOrderId, // Placeholder, you'd look this up
        description: aiItem.itemName,
        brand: aiItem.brand ?? 'unknown',
        unit: aiItem.unit ?? "EA",
        quantity: aiItem.quantity, 
        unitPrice: 0,
      );
    }).toList();

    // 4. Build the full OrderModel
    final newOrder = ModelOrder(
      id: newOrderId,
      description: "",
      userId: customerId,
      partnerId: null,
      estimatedTotal: estimatedTotal,
      deliveryFee: deliveryFee,
      deliveryAddress: "", 
      status: OrderStatus.confirmed,
      items: orderItems,
      createdAt: DateTime.now(),
    );

    // 5. Use the repo to save the new order
    try {
      await _firestoreRepo.addDocument( _collectionPath, newOrder.toMap() ,id: newOrderId);
      logInfo('Successfully created order: $newOrderId');
      return newOrder;
    } catch (e) {
      logError('Failed to save new order: $e');
      rethrow;
    }
  }
  /// Creates a new "draft" order from an AI-parsed order.
  /// This order has no price and is awaiting a quote from a partner.
  Future<ModelOrder> createDraftOrder(ModelChatMessage aiMessage,
      {required String customerId, required String customerName}) async {
    logInfo('Creating draft order for customer: $customerId');
    final aiOrder = aiMessage.parsedOrder!;

    // 1. Generate a unique ID for the draft.
    //final newOrderId = await _firestoreRepo.generateId(_collectionPath);

    // 2. Convert AiParsedItem to OrderItem (price will be 0.0)
    final List<ModelOrderItem> orderItems = aiOrder.requestedItems.map((aiItem) {
      return ModelOrderItem(
        id: aiMessage.id, // No product ID at this stage
        description: aiItem.itemName,
        brand: aiItem.brand ?? 'unknown',
        unit: aiItem.unit ?? "EA",
        quantity: aiItem.quantity,
        unitPrice: 0.0, // Price is unknown in a draft
      );
    }).toList();

    // 3. Build the OrderModel with a 'draft' status
    final newOrder = ModelOrder(
      id: aiMessage.id,
      description: "",
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
      await _firestoreRepo.addDocument(_collectionPath, newOrder.toMap(), id: aiMessage.id);
      logInfo('Successfully created draft order: ${aiMessage.id}');
      return newOrder;
    } catch (e) {
      logError('Failed to save new draft order: $e');
      rethrow;
    }
  }
  /// Updates an existing order with new data.
  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    logInfo('Updating order: $orderId');
    try {
      // We use 'update' here to merge fields, not overwrite the document.
      await _firestoreRepo.updateDocument(_collectionPath, orderId, data);
      logInfo('Successfully updated order: $orderId');
    } catch (e) {
      logError('Failed to update order: $e');
      rethrow;
    }
  }
  /// Deletes an order from the database.
  Future<void> deleteOrder(String orderId) {
    logWarning('Deleting order: $orderId');
    return _firestoreRepo.remove(_collectionPath, orderId);
  }
  /// Updates the status of an existing order.
  // Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
  //   logInfo('Updating order $orderId to status ${newStatus.name}');
  //   return _firestoreRepo.updateDocument(_collectionPath, orderId, {
  //     'status': newStatus.name,
  //   });
  // }

   Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    logInfo('Attempting to update order $orderId to status ${newStatus.name}');
    try {
      final docSnapshot = await _firestoreRepo.getDocumentSnapShot(_collectionPath, orderId);

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        logWarning('Order $orderId not found for status update.');
        throw DatabaseException(
          type: DatabaseErrorType.notFound,
          message: 'Order not found for status update.');
      }

      final currentOrder = ModelOrder.fromMap(docSnapshot.data()!);
      final currentStatus = currentOrder.status;

      // Define allowed transitions
      bool isTransitionAllowed = false;

      // Helper for the target states mentioned in the user's request
      final Set<OrderStatus> allowedTargetStatesFromConfirmedOrQuoted = {
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.assigned,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      };

      switch (currentStatus) {
        case OrderStatus.draft:
          if (newStatus == OrderStatus.awaitingQuote || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.awaitingQuote:
          if (newStatus == OrderStatus.confirmed || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.quoteReceived:
        
        case OrderStatus.confirmed:
          if (allowedTargetStatesFromConfirmedOrQuoted.contains(newStatus)) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.preparing:
          if (newStatus == OrderStatus.readyForPickup || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.readyForPickup:
          if (newStatus == OrderStatus.assigned || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.assigned:
          if (newStatus == OrderStatus.outForDelivery || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.outForDelivery:
          if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
            isTransitionAllowed = true;
          }
          break;
        case OrderStatus.delivered:
        case OrderStatus.cancelled:
          // No further transitions from delivered or cancelled.
          break;
      }

      if (isTransitionAllowed) {
        await _firestoreRepo.updateDocument(_collectionPath, orderId, {
          'status': newStatus.name,
        });
        logInfo('Successfully updated order $orderId from ${currentStatus.name} to ${newStatus.name}');
      } else {
        logWarning('Invalid status transition for order $orderId: from ${currentStatus.name} to ${newStatus.name}');
        throw         throw DatabaseException(
          type: DatabaseErrorType.notFound,
          message: 'Invalid order status transition from ${currentStatus.name} to ${newStatus.name}.');
      }
    } catch (e, s) {
      logError('Failed to update order status for $orderId: $e', stackTrace: s);
      rethrow;
    }
  }
  /// Called by the CLIENT App after user reviews the quote and pays successfully.
  Future<void> confirmOrderPayment(String orderId) async {
    logInfo('User paid. Confirming order: $orderId');
    // await _firestoreRepo.updateDocument(_collectionPath, orderId, {
    //   'status': OrderStatus.confirmed.name,
    //   // You might also save a 'paymentReferenceId' here
    // });
    return updateOrderStatus(orderId, OrderStatus.confirmed);

  }
  /// Assigns an order to a specific rider.
  Future<void> assignRider(String orderId, String riderId) {
    logInfo('Assigning order $orderId to rider $riderId');
    return _firestoreRepo.updateDocument(_collectionPath, orderId, {
      'riderId': riderId,
      'status': OrderStatus.assigned.name, // Business logic!
    });
  }
  
}