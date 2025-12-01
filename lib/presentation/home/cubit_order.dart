import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/service/service_order.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_chat.dart'; // To update bubbles status
import 'package:suefery/locator.dart';
import 'package:suefery/data/model/model_order.dart';
import 'package:suefery/data/model/model_chat_message.dart';
import 'package:suefery/data/model/model_ai_parsed_order.dart';
import 'package:suefery/data/enum/order_status.dart';
import 'package:suefery/data/enum/message_sender.dart';

class StateOrder extends Equatable {
  final List<ModelOrder> orders;
  final bool isLoading;
  const StateOrder({this.orders = const [], this.isLoading = false});

  StateOrder copyWith({List<ModelOrder>? orders, bool? isLoading}) {
    return StateOrder(orders: orders ?? this.orders, isLoading: isLoading ?? this.isLoading);
  }
  @override
  List<Object?> get props => [orders, isLoading];
}

class CubitOrder extends Cubit<StateOrder> with LogMixin {
  final ServiceOrder _orderService = sl<ServiceOrder>();
  final ServiceAuth _authService = sl<ServiceAuth>();
  final ServiceChat _chatService = sl<ServiceChat>();

  CubitOrder() : super(const StateOrder());

  String get currentUserId => _authService.currentAppUser?.id ?? '';
  String get currentUserName => _authService.currentAppUser?.name ?? '';

  void loadPendingOrders() {
    if (currentUserId.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    _orderService.getOrdersForUserStream(currentUserId).listen((orders) {
      emit(state.copyWith(orders: orders, isLoading: false));
    });
  }

  Future<void> submitDraftOrder(ModelChatMessage message) async {
    logInfo('Submitting draft order...');
    if (message.parsedOrder == null) {
      logError('submitDraftOrder failed: message has no parsedOrder.');
      return;
    }

    try {
      // 1. Create the draft order and get its ID from the service.
      // NOTE: This requires `createDraftOrder` to be updated to return `Future<String>`.
      final newOrderId = await _orderService.createDraftOrder(
        message,
        customerId: currentUserId,
        customerName: currentUserName,
      );

      // 2. Link the new orderId to the chat message and save the update.
      final updatedMessage = message.copyWith(
        orderId: newOrderId.id,
        isActioned: true, // Also mark as actioned
        actionStatus: 'AwaitingQuote',
      );
      
      await _chatService.updateMessage(currentUserId, updatedMessage);

      logInfo('Successfully submitted draft order $newOrderId and linked to message ${message.id}');

    } catch (e) {
      logError('Failed to submit draft order: $e');
      // Optionally revert bubble status on failure
      await _updateBubbleStatus(message, 'Draft'); 
      
    }
  }

  Future<void> confirmDraftOrder(ModelChatMessage message) async {
    logInfo('Confirming draft order...');
    if (message.orderId == null) {
      logError('confirmDraftOrder failed: message has no orderId.');
      return;
    }
    try {
      await _orderService.updateOrderStatus(message.orderId!, OrderStatus.awaitingQuote);
      await _updateBubbleStatus(message, 'Confirmed');
    } catch (e) {
      logError('Failed to confirm:$e');
    }
  }

  Future<void> cancelParsedOrder(ModelChatMessage message) async {
     logInfo('Cancelling draft order...');
    if (message.orderId == null) {
      logError('cancelParsedOrder failed: message has no orderId.');
      return;
    }
    try {
      await _orderService.updateOrderStatus(message.orderId!, OrderStatus.cancelled);
      await _updateBubbleStatus(message, 'Cancelled');
    } catch (e) {
      logError('Failed to confirm:$e');
    }
  }

  Future<void> _updateBubbleStatus(ModelChatMessage message, String status, {String? orderId}) async {
    final updated = message.copyWith(isActioned: true, actionStatus: status);
    // This updates Firestore, which CubitChat is listening to, so UI updates automatically!
    await _chatService.updateMessage(currentUserId, updated);
  }

  /// Updates the quantity of an item in a [PendingOrderBubble].
  Future<void> updatePendingOrderItemQuantity (ModelChatMessage message, int itemIndex, int change) async {
    if (message.parsedOrder == null) return;

    final currentItems = message.parsedOrder!.requestedItems;
    if (itemIndex >= currentItems.length) return;

    final newQuantity = currentItems[itemIndex].quantity + change;

    if (newQuantity >= 1) { // Don't allow 0 or less
      // Create new list of items
      final updatedItems = List<ModelAiParsedItem>.from(currentItems);
      updatedItems[itemIndex] =
          updatedItems[itemIndex].copyWith(quantity: newQuantity);

      // Create new parsed order and message
      final updatedParsedOrder = message.parsedOrder!.copyWith(requestedItems: updatedItems);
      final updated = message.copyWith(parsedOrder: updatedParsedOrder);

      await _chatService.updateMessage(currentUserId, updated);
    }
  }

  /// Adds a new item to a pending order in a [DraftOrderBubble].
  Future<void> addPendingOrderItem(ModelChatMessage message, ModelOrderItem item) async {
    if (message.parsedOrder == null) return;

    final currentItems = message.parsedOrder!.requestedItems;
    final updatedItems = List<ModelAiParsedItem>.from(currentItems)..add(
      ModelAiParsedItem(
        itemName: item.description,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        brand: item.brand,
      )
    );

    final updatedParsedOrder = message.parsedOrder!.copyWith(requestedItems: updatedItems);
    final updated = message.copyWith(parsedOrder: updatedParsedOrder);

    await _chatService.updateMessage(currentUserId, updated);
  }

  /// Updates an item in a pending order in a [DraftOrderBubble].
  Future<void> updatePendingOrderItem(ModelChatMessage message, int itemIndex, ModelOrderItem item) async {
    if (message.parsedOrder == null) return;

    final currentItems = message.parsedOrder!.requestedItems;
    if (itemIndex >= currentItems.length) return;

    final updatedItems = List<ModelAiParsedItem>.from(currentItems);
    updatedItems[itemIndex] = ModelAiParsedItem(
        itemName: item.description,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        brand: item.brand,
      );

    final updatedParsedOrder = message.parsedOrder!.copyWith(requestedItems: updatedItems);
    final updated = message.copyWith(parsedOrder: updatedParsedOrder);

    await _chatService.updateMessage(currentUserId, updated);
  }
  
  /// Updates the confirm and pay of an item in a [PendingOrderBubble].
  Future<bool> confirmAndPayForOrder(BuildContext context, ModelAiParsedOrder parsedOrder, ModelChatMessage message) async {
    emit(state.copyWith(isLoading: true));
    // 1. Payment Logic (Mocked)
    bool paymentSuccess = true; 
    
    if (paymentSuccess) {
      try {
        await _updateBubbleStatus(message, 'Paid');
        final newOrder = await _orderService.createOrder(
          parsedOrder,
          customerId: currentUserId,
          customerName: currentUserName,
        );
        await _updateBubbleStatus(message, 'Paid', orderId: newOrder.id);
        
        // Send system message about success
        // Note: To send a message to chat, we might need to access CubitChat or ChatService directly
        await _chatService.saveMessage(currentUserId, ModelChatMessage(
           id: '',
           senderId: 'system',
           senderType: MessageSender.system,
           content: 'Order #${newOrder.id.substring(0,6)} Confirmed!',
           timestamp: DateTime.now()
        ));
        
        emit(state.copyWith(isLoading: false));
        return true;
      } catch (e) {
        logError('Order Creation Failed:$e');
        emit(state.copyWith(isLoading: false));
        return false;
      }
    }
    emit(state.copyWith(isLoading: false));
    return false;
  }

}
