import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingBubble extends StatelessWidget {
  const LoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 10.0, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: double.infinity, height: 10.0, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 40.0, height: 10.0, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
