import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/enum/order_status.dart';

import '../../../../data/enum/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class BubbleOrderConfirmed extends StatelessWidget {
  final OrderSummeryItem item;

  const BubbleOrderConfirmed({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    final orderStatus = OrderStatus.values.firstWhere((e) => e.name == item.id, orElse: () => OrderStatus.draft);

    // Define the steps for the stepper based on OrderStatus
    final steps = [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.assigned,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    int currentStep = steps.indexOf(orderStatus);
    if (currentStep == -1) currentStep = 0; // Default to the first step if status is not in the list

    return BubbleLayout(
      // This could be from MessageSender.system or .gemini
      sender: MessageSender.gemini,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.orderConfirmedTitle(item.orderNumber),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.itemsSummary),
          const SizedBox(height: 8),
          Text(
            strings.totalPrice(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Stepper for order progress
          Stepper(
            currentStep: currentStep,
            controlsBuilder: (context, details) => const SizedBox.shrink(), // Hide controls
            steps: steps.map((status) {
              return Step(
                title: Text(
                  status.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DefaultTextStyle.of(context).style.color,
                  ),
                ),
                content: const SizedBox.shrink(),
                isActive: steps.indexOf(status) <= currentStep,
                state: steps.indexOf(status) < currentStep
                    ? StepState.complete
                    : StepState.indexed,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}