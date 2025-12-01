import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/order_status.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_order.dart';
import 'package:suefery/locator.dart';

// Assuming a model for an order. Create this file if it doesn't exist.
import '../../data/model/model_order.dart';

class StatePendingOrders extends Equatable {
  final List<ModelOrder> pendingOrders;
  final bool isLoading;

  const StatePendingOrders({
    this.pendingOrders = const [],
    this.isLoading = false,
  });

  StatePendingOrders copyWith({
    List<ModelOrder>? pendingOrders,
    bool? isLoading,
  }) {
    return StatePendingOrders(
      pendingOrders: pendingOrders ?? this.pendingOrders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [pendingOrders, isLoading];
}

class CubitPendingOrders extends Cubit<StatePendingOrders> with LogMixin{
  CubitPendingOrders() : super(const StatePendingOrders());

  /// Fetches orders for the current user based on their status.
  Future<List<ModelOrder>?> fetchOrders() async {
    final user = sl<ServiceAuth>().currentAppUser;
    final orderService = sl<ServiceOrder>();

    if (user == null) {
      // Return empty list if no user is logged in
      return [];
    }
    try {
      logInfo('fetching orders');
      final ordersList = await orderService.getOrdersForUser(user.id,statuses: [
        OrderStatus.draft,
        OrderStatus.awaitingQuote,
        OrderStatus.outForDelivery,
        OrderStatus.preparing,
        OrderStatus.quoteReceived,
        OrderStatus.readyForPickup
        ]);
      ordersList == null ? logWarning('no orders found') : logInfo('orders found ${ordersList.length}');
      return ordersList;
    } catch (e) {
      logError('Error fetching orders: $e');
      return [];
    }
  }

  Future<void> loadOrderPending() async {
    emit(state.copyWith(isLoading: true));
    try {
      final orders = await fetchOrders();
      emit(state.copyWith(
        pendingOrders: orders,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
      ));
    }
  }
}