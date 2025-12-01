import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

import '../../data/model/model_order.dart';
import 'cubit_pending_orders.dart';

class ScreenPendingOrders extends StatelessWidget {
  const ScreenPendingOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    // The BlocBuilder will automatically find the CubitPendingOrders instance
    // provided by ScreenHome.
    return Scaffold(
      appBar: AppBar(title: Text(strings.pendingOrdersTextButton)),
      body: BlocProvider(
        create: (context) => CubitPendingOrders()..loadOrderPending(),
        child: BlocBuilder<CubitPendingOrders, StatePendingOrders>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
        
            if (state.pendingOrders.isEmpty) {
              return Center(child: Text(strings.noOrders));
            }
        
            return ListView.builder(
              itemCount: state.pendingOrders.length,
              itemBuilder: (context, index) {
                final ModelOrder order = state.pendingOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${strings.orderId}: ${order.id}'),
                    subtitle: Text(order.description),
                    trailing: Text('\$${order.estimatedTotal.toStringAsFixed(2)}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}