import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

import '../../data/model/model_order.dart';
import 'cubit_order_history.dart';

class ScreenOrderHistory extends StatelessWidget {
  const ScreenOrderHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.historyTitle)),
      body: BlocProvider(
        create: (context) => CubitOrderHistory()..fetchOrders(),
        child: BlocBuilder<CubitOrderHistory, StateOrderHistory>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.historyOrders.isEmpty) {
              return Center(child: Text(strings.noHistory));
            }
            return ListView.builder(
              itemCount: state.historyOrders.length,
              itemBuilder: (context, index) {
                final ModelOrder order = state.historyOrders[index];
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