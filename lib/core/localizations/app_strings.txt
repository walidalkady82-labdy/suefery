import 'package:flutter/material.dart';

class AppStrings {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Suefery',
      'welcome_customer': 'Welcome Customer',
      'welcome_rider': 'Welcome Rider',
      'tab_home': 'Home',
      'tab_history': 'History',
      'start_order': 'Start New Order',
      'track_order': 'Track Your Order',
      'active_orders': 'Active Orders',
      'past_orders': 'Past Orders',
      'no_active_orders': 'You have no active orders being processed right now.',
      'no_past_orders': 'You have no completed orders yet.',
      'order_id': 'Order ID',
      'status': 'Status',
      'store': 'Store',
      'total': 'Total',
      'rider': 'Rider',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'assigned': 'Assigned',
      'new': 'New',
      'logout': 'Logout',
      'tab_unassigned': 'New Orders',
      'tab_active': 'Active Delivery',
      'unassigned_list_title': 'Available Orders',
      'no_unassigned_orders': 'No new orders right now. Check back soon!',
      'address': 'Delivery Address',
      'accept_order': 'Accept Delivery',
      'active_delivery_title': 'Current Delivery',
      'no_active_delivery': 'You haven\'t accepted an order yet.',
      'current_status': 'Current Status',
      'rider_action_pickup': 'Mark as Picked Up',
      'rider_action_delivered': 'Mark as Delivered',
      'customer_id': 'User ID',
      'chat_title': 'Chat with Rider',
      'send': 'Send',
      'type_message': 'Type a message...',
      'chat_rider': 'Chat with Rider',
      'chat_customer': 'Chat with Customer',
    },
  };

  static String get(BuildContext context, String key) {
    // In a real app, this would use Localizations.localeOf(context)
    final map = _localizedValues['en']!; 
    return map[key] ?? key;
  }
}

// Extension to safely get the first element matching a condition (used in Rider Dashboard)
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}