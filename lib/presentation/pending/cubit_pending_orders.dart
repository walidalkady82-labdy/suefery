import 'dart:async';

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
  StreamSubscription? _orderSubscription;


  void loadOrderPending() {
    final user = sl<ServiceAuth>().currentAppUser;
    final orderService = sl<ServiceOrder>();

    if (user == null) {
      emit(state.copyWith(pendingOrders: []));
      return;
    }

    emit(state.copyWith(isLoading: true));
    _orderSubscription?.cancel();
    _orderSubscription = orderService.getOrdersForUserStream(user.id, statuses: [
      OrderStatus.draft,
      OrderStatus.awaitingQuote,
      OrderStatus.outForDelivery,
      OrderStatus.preparing,
      OrderStatus.quoteReceived,
      OrderStatus.readyForPickup
    ]).listen((orders) {
      emit(state.copyWith(pendingOrders: orders, isLoading: false));
    }, onError: (e) {
      logError('Error fetching pending orders: $e');
      emit(state.copyWith(isLoading: false));
    });
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}