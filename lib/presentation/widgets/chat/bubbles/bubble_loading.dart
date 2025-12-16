import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../data/enum/message_sender.dart';
import 'bubble_layout.dart';

class BubbleLoading extends StatelessWidget {
  const BubbleLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the bubble's background color for shimmer
    final baseColor = theme.colorScheme.secondaryContainer;
    final highlightColor = theme.colorScheme.onSecondaryContainer..withAlpha(128);

    return BubbleLayout(
      sender: MessageSender.gemini,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use containers that mimic the bubble's background
            Container(width: double.infinity, height: 10.0, color: baseColor),
            const SizedBox(height: 6),
            Container(width: double.infinity, height: 10.0, color: baseColor),
            const SizedBox(height: 6),
            Container(width: 40.0, height: 10.0, color: baseColor),
          ],
        ),
      ),
    );
  }
}