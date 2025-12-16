import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_item.dart';
import 'package:suefery/presentation/widgets/chat/bubbles/bubble_layout.dart';
import 'package:suefery/data/enum/message_sender.dart';

import '../../../../data/enum/promotion_type.dart';

class BubblePromotion extends StatelessWidget {
  final PromotionItem item;

  const BubblePromotion({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // --- 1. THE SWITCH LOGIC ---
    // We determine the "Mode" based on the enum type.
    final isLoyaltyReward = item.type == PromotionType.customerSpecific;

    // --- 2. DYNAMIC STYLING ---
    // If Loyalty -> Amber (Gold). If Item Deal -> Blue.
    final Color mainColor = isLoyaltyReward ? Colors.amber.shade800 : Colors.blue.shade700;
    final Color lightBg = isLoyaltyReward ? Colors.amber.shade50 : Colors.blue.shade50;
    final String badgeText = isLoyaltyReward ? "EXCLUSIVE REWARD" : "ITEM DEAL";
    final IconData icon = isLoyaltyReward ? Icons.star : Icons.discount;

    return BubbleLayout(
      sender: MessageSender.gemini,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A. Optional Image Banner
          if (item.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => const SizedBox.shrink(),
                ),
              ),
            ),

          // B. The Badge (Changes Color & Text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: lightBg, // <--- Dynamic Background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: mainColor..withAlpha(128)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: mainColor), // <--- Dynamic Icon
                const SizedBox(width: 4),
                Text(
                  badgeText, // <--- Dynamic Text
                  style: TextStyle(
                    color: mainColor, // <--- Dynamic Text Color
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // C. Main Title & Description
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          
          // --- 3. DYNAMIC CONTENT (THE TAGS) ---
          // Only show this section if it is an Item Deal AND has items listed.
          if (!isLoyaltyReward && item.eligibleItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Valid on:",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 10),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.eligibleItems.map((itemName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    itemName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // D. The Promo Code "Ticket" (Changes Border Color)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.promoCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Code '${item.promoCode}' copied!")),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                // Dashed border effect simulated with simple border here
                border: Border.all(
                  color: mainColor.withAlpha(128), // <--- Dynamic Border Color
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TAP TO COPY CODE",
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.promoCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: mainColor, // <--- Dynamic Text Color
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.copy, color: mainColor, size: 20), // <--- Dynamic Icon Color
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}