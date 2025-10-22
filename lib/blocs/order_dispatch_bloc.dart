import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';

// Helper function for Firebase Initialization (must be run once)
Future<FirebaseFirestore> initializeFirestore() async {
  // Global variables provided by the canvas environment
  const String appId = bool.fromEnvironment('dart.vm.product') ? 'prod-app-id' : 'default-app-id';
  final Map<String, dynamic> firebaseConfig = const bool.fromEnvironment('dart.vm.product') ? {} : {}; // Mocking empty config if not provided

  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    // Use FirebaseOptions.fromMap for initialization
    await Firebase.initializeApp(options: FirebaseOptions.fromMap(firebaseConfig));
  }
  
  // Set up authentication for the current user session
  final FirebaseAuth auth = FirebaseAuth.instance;
  // This custom token is provided by the canvas environment
  final String? initialAuthToken = null; 

  if (initialAuthToken != null && auth.currentUser == null) {
    try {
      await auth.signInWithCustomToken(initialAuthToken!);
    } catch (e) {
      // If token fails, sign in anonymously as a fallback
      await auth.signInAnonymously();
    }
  } else if (auth.currentUser == null) {
     await auth.signInAnonymously();
  }
  
  return FirebaseFirestore.instance;
}

// --- Events ---
sealed class OrderDispatchEvent {
  const OrderDispatchEvent();
}

class TrackOrders extends OrderDispatchEvent {
  final String userId;
  const TrackOrders(this.userId);
}

class StartNewOrder extends OrderDispatchEvent {
  final OrderModel order;
  const StartNewOrder(this.order);
}

class AcceptOrder extends OrderDispatchEvent {
  final int orderId;
  final String riderId;
  const AcceptOrder(this.orderId, this.riderId);
}

class UpdateOrderStatus extends OrderDispatchEvent {
  final int orderId;
  final OrderStatus status;
  const UpdateOrderStatus(this.orderId, this.status);
}

class UpdateOrderProgress extends OrderDispatchEvent {
  final int orderId;
  final double progress;
  const UpdateOrderProgress(this.orderId, this.progress);
}

class _UpdateOrders extends OrderDispatchEvent {
  final List<OrderModel> orders;
  const _UpdateOrders(this.orders);
}


// --- State ---
class OrderDispatchState {
  final List<OrderModel> allOrders;
  final bool isLoading;
  // Filtered lists for convenience
  List<OrderModel> get allUnassignedOrders => allOrders
      .where((o) => o.status == OrderStatus.New)
      .toList();

  const OrderDispatchState({
    this.allOrders = const [],
    this.isLoading = false,
  });

  OrderDispatchState copyWith({
    List<OrderModel>? allOrders,
    bool? isLoading,
  }) {
    return OrderDispatchState(
      allOrders: allOrders ?? this.allOrders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLoC ---
class OrderDispatchBloc extends Bloc<OrderDispatchEvent, OrderDispatchState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _orderSubscription;

  // Collection Path: /artifacts/{appId}/public/data/orders/{orderId}
  static const String _collectionPath = 'artifacts/default-app-id/public/data/orders';

  OrderDispatchBloc() : super(const OrderDispatchState(isLoading: true)) {
    on<TrackOrders>(_onTrackOrders);
    on<StartNewOrder>(_onStartNewOrder);
    on<AcceptOrder>(_onAcceptOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<UpdateOrderProgress>(_onUpdateOrderProgress);
    on<_UpdateOrders>(_onUpdateOrders);
  }

  void _onTrackOrders(TrackOrders event, Emitter<OrderDispatchState> emit) {
    if (_orderSubscription != null) return;
    
    final ordersCollection = _firestore.collection(_collectionPath);

    // Track all orders globally for simplicity in this public demo
    _orderSubscription = ordersCollection.snapshots().listen((snapshot) {
      final orders = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      add(_UpdateOrders(orders));
    });

    emit(state.copyWith(isLoading: true));
  }
  
  void _onStartNewOrder(StartNewOrder event, Emitter<OrderDispatchState> emit) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc(event.order.orderId.toString());
      await docRef.set(event.order.toMap());
      print('Order ${event.order.orderId} started successfully.');
    } catch (e) {
      print('Error starting new order: $e');
    }
  }

  void _onAcceptOrder(AcceptOrder event, Emitter<OrderDispatchState> emit) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc(event.orderId.toString());
      
      // Update the status and assign the rider
      await docRef.update({
        'riderId': event.riderId,
        'status': OrderStatus.Assigned.name,
        'progress': 0.1, // Initial progress
      });
      print('Order ${event.orderId} accepted by rider ${event.riderId}');
    } catch (e) {
      print('Error accepting order: $e');
    }
  }

  void _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<OrderDispatchState> emit) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc(event.orderId.toString());
      
      await docRef.update({
        'status': event.status.name,
        'progress': event.status == OrderStatus.Delivered ? 1.0 : 0.0,
      });
      print('Order ${event.orderId} status updated to ${event.status.name}');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  void _onUpdateOrderProgress(UpdateOrderProgress event, Emitter<OrderDispatchState> emit) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc(event.orderId.toString());
      await docRef.update({'progress': event.progress});
      print('Order ${event.orderId} progress updated to ${event.progress}');
    } catch (e) {
      print('Error updating order progress: $e');
    }
  }

  void _onUpdateOrders(_UpdateOrders event, Emitter<OrderDispatchState> emit) {
    emit(state.copyWith(allOrders: event.orders, isLoading: false));
  }

  @override
  Future<void> close() {
    // Cancel the Firestore listener when the BLoC is closed
    _orderSubscription?.cancel();
    return super.close();
  }
}
