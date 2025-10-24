import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/firebase_service.dart';
import '../services/logging_service.dart';

final _log = LoggerReprository('orderHistoryBloc');
// --- STATES ---

/// Base state for the Order History feature.
abstract class OrderHistoryState {}

/// Initial state when the history screen loads.
class OrderHistoryInitial extends OrderHistoryState {}

/// State indicating that order history data is being fetched.
class OrderHistoryLoading extends OrderHistoryState {}

/// State indicating that order history data has been successfully loaded.
class OrderHistoryLoaded extends OrderHistoryState {
  final List<Order> orders;

  OrderHistoryLoaded(this.orders);
}

// --- EVENTS ---

/// Event to trigger the loading of the order history.
class LoadOrderHistory extends OrderHistoryEvent {}

/// Base event for the Order History feature.
abstract class OrderHistoryEvent {}

// --- BLoC ---

/// BLoC for managing the state of the Order History screen.
class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  // Stream subscription to listen for Firestore changes
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;

  OrderHistoryBloc() : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
  }

  /// Handles loading and streaming order history from Firestore.
  Future<void> _onLoadOrderHistory(
    LoadOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());

    final service = FirebaseService.instance;

    // Use a stream to listen for real-time updates (onSnapshot equivalent)
    try {
      final ordersCollectionRef = service.firestore.collection(service.userOrdersCollectionPath);

      // The query fetches all orders for the current user, sorted by date (newest first).
      // Note: We avoid orderBy() to comply with the constraint of avoiding index requirements,
      // and will sort the results in memory.
      final query = ordersCollectionRef;

      _ordersSubscription = query.snapshots().listen(
        (snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromFirestore(doc))
              .toList();
          
          // Sort in memory (newest first) to avoid Firestore index requirements
          orders.sort((a, b) => b.date.compareTo(a.date));

          emit(OrderHistoryLoaded(orders));
          _log.e('Firestore: Successfully streamed ${orders.length} orders.');

          // For the first run, let's inject some mock data if the collection is empty
          if (orders.isEmpty) {
             _seedInitialMockData(service);
          }
        },
        onError: (error) {
          _log.e('Firestore Error: Failed to stream orders: $error');
          emit(OrderHistoryLoaded([]));
        },
      );
    } catch (e) {
      _log.e('Firestore Setup Error: $e');
      emit(OrderHistoryLoaded([]));
    }
  }
  
  /// Helper to create initial data if the collection is empty.
  void _seedInitialMockData(FirebaseService service) {
    final CollectionReference<Map<String, dynamic>> ordersRef = 
        service.firestore.collection(service.userOrdersCollectionPath);

    final PartnerStore miniMart = PartnerStore(
      id: 'store_1',
      name: 'University Mini-Mart',
      locationAddress: 'Building A, Beni Suef Campus',
    );

    final order1Items = [
      OrderItem(id: 'item_1', name: 'Coffee Blend (250g)', quantity: 2, unitPrice: 85.0, partnerStoreId: miniMart.id),
      OrderItem(id: 'item_2', name: 'Mineral Water (1.5L)', quantity: 1, unitPrice: 12.0, partnerStoreId: miniMart.id),
    ];

    final order2Items = [
      OrderItem(id: 'item_3', name: 'Aish Baladi Bread', quantity: 5, unitPrice: 1.5, partnerStoreId: miniMart.id),
      OrderItem(id: 'item_4', name: 'Nutella Jar (350g)', quantity: 1, unitPrice: 95.0, partnerStoreId: miniMart.id),
    ];

    final mockOrders = [
      Order(
        id: 'SUE1001',
        userId: service.userId,
        date: DateTime.now().subtract(const Duration(hours: 3)),
        items: order1Items,
        status: OrderStatus.delivered,
        deliveryFee: 5.0,
      ),
      Order(
        id: 'SUE1002',
        userId: service.userId,
        date: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
        items: order2Items,
        status: OrderStatus.delivered,
        deliveryFee: 5.0,
      ),
      Order(
        id: 'SUE1003',
        userId: service.userId,
        date: DateTime.now().subtract(const Duration(days: 5)),
        items: order1Items,
        status: OrderStatus.cancelled,
        deliveryFee: 5.0,
      ),
    ];
    
    // Write mock data to Firestore so the stream picks it up
    for (var order in mockOrders) {
      ordersRef.doc(order.id).set(order.toFirestore());
    }
    _log.i('Firestore: Seeded initial mock data.');
  }


  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
