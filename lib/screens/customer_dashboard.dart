import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/order_dispatch/order_dispatch_bloc.dart';
import '../models/models.dart';
import '../widgets/order_history_card.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  late final String _customerId;

  @override
  void initState() {
    super.initState();
    // Get the User ID from Auth State
    _customerId = context.read<AuthBloc>().state.userId;
    // Start tracking orders relevant to this user
    context.read<OrderDispatchBloc>().add(TrackOrders(_customerId));
  }

  void _startNewOrder(BuildContext context) {
    final newOrder = OrderModel(
      orderId: Random().nextInt(999999) + 100000,
      customerId: _customerId,
      storeName: 'QuickMart Groceries',
      estimatedTotal: (Random().nextDouble() * 500) + 50,
      deliveryAddress: 'Apt 4B, Cairo, Egypt',
      status: OrderStatus.New,
      progress: 0.0,
      items: [
        {'name': 'Milk', 'qty': 1},
        {'name': 'Bread', 'qty': 2},
      ],
    );
    context.read<OrderDispatchBloc>().add(StartNewOrder(newOrder));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'app_name')),
        backgroundColor: Colors.indigo.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.delivery_dining),
            onPressed: () => context.read<AuthBloc>().add(const ChangeRole(UserRole.rider)),
            tooltip: 'Switch to Rider',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const ChangeRole(UserRole.rider)), // Mock logout
            tooltip: AppStrings.get(context, 'logout'),
          ),
        ],
      ),
      body: BlocBuilder<OrderDispatchBloc, OrderDispatchState>(
        builder: (context, state) {
          final customerOrders = state.allOrders
              .where((o) => o.customerId == _customerId)
              .toList();

          final activeOrders = customerOrders
              .where((o) => o.status != OrderStatus.Delivered && o.status != OrderStatus.Cancelled)
              .toList();
          
          final pastOrders = customerOrders
              .where((o) => o.status == OrderStatus.Delivered || o.status == OrderStatus.Cancelled)
              .toList();

          return IndexedStack(
            index: _currentIndex,
            children: [
              _HomeTab(
                isLoading: state.isLoading,
                activeOrders: activeOrders,
                customerId: _customerId,
                onStartOrder: () => _startNewOrder(context),
              ),
              _HistoryTab(
                isLoading: state.isLoading,
                pastOrders: pastOrders,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo.shade700,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.get(context, 'tab_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppStrings.get(context, 'tab_history'),
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: Home View ---

class _HomeTab extends StatelessWidget {
  final List<OrderModel> activeOrders;
  final bool isLoading;
  final String customerId;
  final VoidCallback onStartOrder;

  const _HomeTab({
    required this.activeOrders,
    required this.isLoading,
    required this.customerId,
    required this.onStartOrder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.get(context, 'welcome_customer')} (${AppStrings.get(context, 'customer_id')}: ${customerId})',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
          ),
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartOrder,
              icon: const Icon(Icons.add_shopping_cart, size: 24),
              label: Text(AppStrings.get(context, 'start_order')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          Text(
            AppStrings.get(context, 'active_orders'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
            ),
          ),
          const Divider(height: 20),

          isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeOrders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                          AppStrings.get(context, 'no_active_orders'),
                          style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeOrders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: OrderHistoryCard(order: activeOrders[index]),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

// --- TAB 2: History View ---

class _HistoryTab extends StatelessWidget {
  final List<OrderModel> pastOrders;
  final bool isLoading;

  const _HistoryTab({required this.pastOrders, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return isLoading 
        ? const Center(child: CircularProgressIndicator())
        : pastOrders.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    AppStrings.get(context, 'no_past_orders'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: pastOrders.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: OrderHistoryCard(order: pastOrders[index]),
                  );
                },
              );
  }
}
