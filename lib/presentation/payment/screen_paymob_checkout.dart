import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
// The main import should be sufficient as it exports the response model.
import 'package:flutter_paymob/flutter_paymob.dart';
// import 'package:suefery/locator.dart';

// import '../../data/service/service_auth.dart';

class ScreenPaymobCheckout extends StatefulWidget {
  final double amount;
  const ScreenPaymobCheckout(
      {super.key, required this.amount});

  @override
  State<ScreenPaymobCheckout> createState() => _ScreenPaymobCheckoutState();
}

class _ScreenPaymobCheckoutState extends State<ScreenPaymobCheckout> {
  bool _isProcessing = false;
  //final ServiceAuth _authService = sl<ServiceAuth>();
  // --- Pay with Card via Backend ---
  Future<void> _startCardPayment(BuildContext context) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Call the Firebase Function to get the payment key.
      // final callable = FirebaseFunctions.instance.httpsCallable('createPaymobPaymentIntent');

      // final response = await callable.call(<String, dynamic>{
      //   'amount': widget.amount,
      //   'currency': 'EGP',
      //   'billingData': _authService.currentAppUser?.toMap(),
      // });

      //final paymentKey = response.data['paymentKey'];
      // 2. Use the payment key to launch the Paymob SDK
      // await FlutterPaymob.instance.pay(
      //   context: context,
      //   paymentKey: paymentKey,
      //   // The currency and amount are already associated with the payment key
      //   // on the backend, so they are not needed here.
      //   onPayment: _handlePaymentResponse,
      // );
    } on FirebaseFunctionsException catch (e) {
      debugPrint("Firebase Function Error: ${e.code} - ${e.message}");
      // Consider logging the stack trace for more detailed debugging.
      // logger.e("Firebase Function Error", error: e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Payment Failed: ${e.message ?? 'An unknown error occurred.'}")),
      );
    } catch (error) {
      debugPrint("Generic Payment Error: $error");
      // Consider logging the stack trace for more detailed debugging.
      // logger.e("Generic Payment Error", error: error, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("An unexpected error occurred: $error")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // --- Option 2: Pay with Mobile Wallet ---
  Future<void> _payWithWallet(BuildContext context) async {
    try {
      await FlutterPaymob.instance.payWithWallet(
        context: context,
        currency: "EGP",
        amount: widget.amount,
        number: "010xxxxxxxx", // The customer's wallet number
        //onPayment: _handlePaymentResponse,
      );
    } catch (e) {
      debugPrint("Wallet Payment Error: $e");

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //       backgroundColor: Colors.red,
      //       content: Text("An unexpected error occurred: $e")),
      // );

    }
  }

  // void _handlePaymentResponse(PaymobResponse response) {
  //   // Handle the immediate response from the SDK view
  //   if (!mounted) return;

  //   String message = response.message;

  //   if (response.success == true) {
  //     // Payment was successful, pop the screen and return the response object.
  //     debugPrint("Payment Successful: ${response.id}");
  //     Navigator.of(context).pop(response);
  //     return;
  //   } else if (message == "User cancelled" || message == "Cancelled") {
  //     // User closed the payment sheet, pop and return null.
  //     Navigator.of(context).pop();
  //     return;
  //   } else {
  //     // For wallets, "success" can be false if the request was just sent, so we show a different message.
  //     message = response.isWallet ? "Wallet request sent. Please check your SMS/Wallet app to complete the payment." : "Payment Failed: $message";
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(backgroundColor: response.isWallet ? Colors.orangeAccent : Colors.red, content: Text(message)),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paymob Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.credit_card),
                label: Text("Pay ${widget.amount} EGP via Card"),
                onPressed: () => _startCardPayment(context),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              // The wallet button should also be disabled during processing.
              onPressed: _isProcessing ? null : () => _payWithWallet(context),
              icon: const Icon(Icons.phone_android),
              label: Text("Pay ${widget.amount} EGP via Wallet"),
            ),
          ],
        ),
      ),
    );
  }
}