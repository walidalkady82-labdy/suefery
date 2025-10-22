import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:beni_suef_delivers/main.dart'; // Still using original file path
import 'package:beni_suef_delivers/blocs/order_dispatch/order_dispatch_bloc.dart';
import 'package:beni_suef_delivers/models/models.dart';

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = (String key) => AppStrings.get(context, key);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suefery Partner Hub (Store)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      backgroundColor: Colors.blueGrey.shade50,
      body: BlocBuilder<OrderDispatchBloc, OrderDispatchState>(
        builder: (context, state) {
          final processingOrders = state.orders.where((o) => o.status == tr('status_processing')).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders to Fulfill (${processingOrders.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const Divider(),
                Expanded(
                  child: processingOrders.isEmpty
                      ? Center(child: Text('No new orders to fulfill.', style: TextStyle(color: Colors.grey.shade600)))
                      : ListView.builder(
                          itemCount: processingOrders.length,
                          itemBuilder: (context, index) {
                            final order = processingOrders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(Icons.store, color: Colors.blueGrey.shade400),
                                title: Text('Order #${order.id.substring(0, 8)}'),
                                subtitle: Text('Items: ${order.description}\nTime: ${order.timestamp.hour}:${order.timestamp.minute}'),
                                trailing: Text(order.status, style: TextStyle(color: order.statusColor, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
