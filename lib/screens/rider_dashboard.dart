import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/order_dispatch/order_dispatch_bloc.dart';
import '../models/models.dart';
import '../widgets/chat_button.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _currentIndex = 0;
  // Rider ID comes from Auth State
  late final String _riderId; 

  @override
  void initState() {
    super.initState();
    _riderId = context.read<AuthBloc>().state.userId;
    // Start tracking both unassigned and this rider's active orders
    context.read<OrderDispatchBloc>().add(TrackOrders(_riderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'app_name')),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => context.read<AuthBloc>().add(const ChangeRole(UserRole.customer)),
            tooltip: 'Switch to Customer',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const ChangeRole(UserRole.customer)), // Mock logout
            tooltip: AppStrings.get(context, 'logout'),
          ),
        ],
      ),
      body: BlocBuilder<OrderDispatchBloc, OrderDispatchState>(
        builder: (context, state) {
          // Filter orders relevant to the rider
          final unassignedOrders = state.allUnassignedOrders;
          // Find the active delivery for THIS rider
          final activeDelivery = state.allOrders.firstWhereOrNull((order) => order.riderId == _riderId && order.status != OrderStatus.Delivered && order.status != OrderStatus.Cancelled);

          return IndexedStack(
            index: _currentIndex,
            children: [
              _UnassignedOrdersTab(
                unassignedOrders: unassignedOrders,
                riderId: _riderId,
              ),
              _ActiveDeliveryTab(
                activeOrder: activeDelivery,
                riderId: _riderId,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade700,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: AppStrings.get(context, 'tab_unassigned'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.motorcycle),
            label: AppStrings.get(context, 'tab_active'),
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: Unassigned Orders List ---

class _UnassignedOrdersTab extends StatelessWidget {
  final List<OrderModel> unassignedOrders;
  final String riderId;

  const _UnassignedOrdersTab({required this.unassignedOrders, required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.get(context, 'welcome_rider')} (${AppStrings.get(context, 'customer_id')}: ${riderId})',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.get(context, 'unassigned_list_title'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade600,
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: unassignedOrders.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.get(context, 'no_unassigned_orders'),
                      style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: unassignedOrders.length,
                    itemBuilder: (context, index) {
                      final order = unassignedOrders[index];
                      return _UnassignedOrderCard(order: order, riderId: riderId);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UnassignedOrderCard extends StatelessWidget {
  final OrderModel order;
  final String riderId;

  const _UnassignedOrderCard({required this.order, required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.get(context, 'order_id')}${order.orderId}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
            const Divider(),
            _buildDetailRow(context, AppStrings.get(context, 'store'), order.storeName, Icons.store),
            _buildDetailRow(context, AppStrings.get(context, 'address'), order.deliveryAddress, Icons.location_on),
            _buildDetailRow(context, AppStrings.get(context, 'total'), '${order.estimatedTotal.toStringAsFixed(2)} EGP', Icons.attach_money),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<OrderDispatchBloc>().add(AcceptOrder(order.orderId, riderId));
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                label: Text(AppStrings.get(context, 'accept_order')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TAB 2: Active Delivery View ---

class _ActiveDeliveryTab extends StatelessWidget {
  final OrderModel? activeOrder;
  final String riderId;

  const _ActiveDeliveryTab({this.activeOrder, required this.riderId});

  @override
  Widget build(BuildContext context) {
    if (activeOrder == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bike, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                AppStrings.get(context, 'no_active_delivery'),
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Determine the next action button
    String nextActionText;
    OrderStatus nextStatus;
    IconData nextIcon;
    Color nextColor;
    double newProgress;

    if (activeOrder!.progress < 0.5) {
      // Step 1: Assigned (0.1) -> Picked Up (0.75)
      nextActionText = AppStrings.get(context, 'rider_action_pickup');
      nextStatus = activeOrder!.status; // Status remains Assigned until delivered
      nextIcon = Icons.shopping_bag_outlined;
      nextColor = Colors.orange.shade700;
      newProgress = 0.75;
    } else {
      // Step 2: Picked Up (0.75) -> Delivered (1.0)
      nextActionText = AppStrings.get(context, 'rider_action_delivered');
      nextStatus = OrderStatus.Delivered;
      nextIcon = Icons.done_all;
      nextColor = Colors.green.shade700;
      newProgress = 1.0;
    }
    
    // Simulate current status display based on progress
    String currentStatus = activeOrder!.progress < 0.5 ? "Heading to Store for Pickup" : "En Route to Customer";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get(context, 'active_delivery_title'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
              const Divider(height: 25),
              _buildDetailRow(context, AppStrings.get(context, 'order_id'), activeOrder!.orderId.toString(), Icons.receipt),
              _buildDetailRow(context, AppStrings.get(context, 'customer_id'), activeOrder!.customerId, Icons.person),
              _buildDetailRow(context, AppStrings.get(context, 'store'), activeOrder!.storeName, Icons.store),
              _buildDetailRow(context, AppStrings.get(context, 'address'), activeOrder!.deliveryAddress, Icons.location_on),
              const SizedBox(height: 15),

              // Status and Progress
              Text(
                '${AppStrings.get(context, 'current_status')}: $currentStatus',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: activeOrder!.progress,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons (Chat & Status Update)
              Row(
                children: [
                  ChatButton(
                    order: activeOrder!,
                    buttonLabel: AppStrings.get(context, 'chat_customer'),
                    icon: Icons.chat,
                    isEnabled: true, // Rider can always chat with customer on active order
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nextStatus == OrderStatus.Delivered) {
                          context.read<OrderDispatchBloc>().add(UpdateOrderStatus(activeOrder!.orderId, OrderStatus.Delivered));
                        } else {
                          context.read<OrderDispatchBloc>().add(UpdateOrderProgress(activeOrder!.orderId, newProgress));
                        }
                      },
                      icon: Icon(nextIcon, color: Colors.white),
                      label: Text(nextActionText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nextColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
