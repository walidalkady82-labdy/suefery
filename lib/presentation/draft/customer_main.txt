import 'package:flutter/material.dart';

class CustomerAppScreen extends StatelessWidget {
  const CustomerAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = Localizations.of(context);
    final isArabic = i18n.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('customer_title')),
        backgroundColor: const Color(0xFFE5002D), // Customer focus color (Red)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Ensure the text flows correctly for RTL languages
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Welcome Text / USP Highlight
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      i18n.translate('welcome_customer'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00308F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Visual cue for conversational ordering
                    const Icon(Icons.mic, size: 48, color: Color(0xFFE5002D)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Button 1: Place Order (S1 Feature)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to the Gemini Voice Ordering screen
                  _showMessage(context, 'Feature Pending: ${i18n.translate('button_order')}');
                },
                icon: const Icon(Icons.voice_chat, size: 28),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    i18n.translate('button_order'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5002D), // Red for action
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),

              // Button 2: Order History
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to Order History
                  _showMessage(context, 'Feature Pending: ${i18n.translate('button_history')}');
                },
                icon: const Icon(Icons.history, size: 28),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    i18n.translate('button_history'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00308F),
                  side: const BorderSide(color: Color(0xFF00308F), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const Spacer(),
              const Text(
                'Hyper-Local Efficiency (S3) guarantees <= 15 min ADT.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple, custom message function to replace alert()
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}