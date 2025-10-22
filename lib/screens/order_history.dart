import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/order_dispatch/order_dispatch_bloc.dart';
import '../widgets/order_history_card.dart';
import '../models/models.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure we are tracking orders for the current customer (mocked as Customer_A)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderDispatchBloc>().add(const TrackOrders('Customer_A'));
    });

    return BlocBuilder<OrderDispatchBloc, OrderDispatchState>(
      builder: (context, state) {
        // Filter orders into active and past categories
        final activeOrders = state.customerOrders.where((o) => o.status != OrderStatus.Delivered && o.status != OrderStatus.Cancelled).toList();
        final pastOrders = state.customerOrders.where((o) => o.status == OrderStatus.Delivered || o.status == OrderStatus.Cancelled).toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Active Orders Section ---
            _buildSectionHeader(context, AppStrings.get(context, 'active_orders'), Colors.blue.shade800),
            const SizedBox(height: 10),
            if (activeOrders.isEmpty)
              _buildEmptyState(context, AppStrings.get(context, 'no_active_orders'))
            else
              ...activeOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: OrderHistoryCard(order: order),
              )).toList(),

            const SizedBox(height: 25),
            
            // --- Past Orders Section ---
            _buildSectionHeader(context, AppStrings.get(context, 'past_orders'), Colors.green.shade800),
            const SizedBox(height: 10),
            if (pastOrders.isEmpty)
              _buildEmptyState(context, AppStrings.get(context, 'no_past_orders'))
            else
              ...pastOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: OrderHistoryCard(order: order),
              )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
