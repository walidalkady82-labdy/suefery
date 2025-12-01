import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/order_status.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_order.dart';
import 'package:suefery/locator.dart';

// Assuming a model for an order. Create this file if it doesn't exist.
import '../../data/model/model_order.dart';

class StateOrderHistory extends Equatable {
  final List<ModelOrder> historyOrders;
  final bool isLoading;

  const StateOrderHistory({
    this.historyOrders = const [],
    this.isLoading = false,
  });

  StateOrderHistory copyWith({
    List<ModelOrder>? historyOrders,
    bool? isLoading,
  }) {
    return StateOrderHistory(
      historyOrders: historyOrders ?? this.historyOrders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [historyOrders, isLoading];
}

class CubitOrderHistory extends Cubit<StateOrderHistory> with LogMixin {
  CubitOrderHistory() : super(const StateOrderHistory());

  /// Fetches orders for the current user based on their status.
  Future<List<ModelOrder>?> fetchOrders() async {
    final user = sl<ServiceAuth>().currentAppUser;
    final orderService = sl<ServiceOrder>();

    if (user == null) {
      logError('no user is logged in');
      return [];
    }
    try {
      logInfo('fetching orders');
      final ordersList = await orderService.getOrdersForUser(user.id,statuses: [
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]);
      ordersList == null ? logWarning('no orders found') : logInfo('orders found ${ordersList.length}');
      return ordersList;
    } catch (e) {
      logError('Error fetching orders: $e');
      return [];
    }
  }

  Future<void> loadOrderHistory() async {
    emit(state.copyWith(isLoading: true));
    try {
      final orders = await fetchOrders();
      emit(state.copyWith(
        historyOrders: orders,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
      ));
    }
  }

}