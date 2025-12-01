// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http; // For calling the backend
// import 'dart:convert';


// ignore: dangling_library_doc_comments
/// A service to handle payment processing logic.
// class PaymentService {
//   final _log = LogRepo('PaymentService');

//   /// Initiates the payment process.
//   ///
//   /// 1. Call your backend to create a payment intent with the amount.
//   /// 2. Use the payment gateway's SDK to show a payment UI (e.g., Stripe's PaymentSheet).
//   /// 3. Return `true` for success or `false` for failure.
//   Future<bool> processPayment({
//     required BuildContext context,
//     required double amount,
//     required String currency,
//     required String customerName,
//   }) async {
//     try {
//       // --- 1. Create Payment Intent on the backend ---
//       final clientSecret = await _createPaymentIntent(amount, currency, customerName);

//       if (clientSecret == null) {
//         _log.e('Failed to create payment intent.');
//         return false;
//       }

//       // --- 2. Initialize the Payment Sheet ---
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'Suefery',
//           // You can also pass customer details here
//         ),
//       );

//       // --- 3. Present the Payment Sheet to the user ---
//       await Stripe.instance.presentPaymentSheet();

//       _log.i('Payment completed successfully!');
//       return true;
//     } on StripeException catch (e) {
//       // This exception is thrown when the user cancels the payment sheet or if payment fails.
//       if (e.error.code == FailureCode.Canceled) {
//         _log.i('Payment was cancelled by the user.');
//       } else {
//         _log.e('Stripe payment failed: ${e.error.message}');
//       }
//       return false;
//     } catch (e) {
//       _log.e('An unexpected error occurred during payment: $e');
//       return false;
//     }
//   }

//   /// Calls your backend to create a Stripe Payment Intent.
//   Future<String?> _createPaymentIntent(double amount, String currency, String customerName) async {
//     try {
//       // IMPORTANT: Replace with your actual backend endpoint URL
//       final url = Uri.parse('https://us-central1-your-project-id.cloudfunctions.net/createPaymentIntent');

//       // Stripe expects the amount in the smallest currency unit (e.g., piastres for EGP)
//       final amountInSmallestUnit = (amount * 100).round();

//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'amount': amountInSmallestUnit,
//           'currency': currency.toLowerCase(),
//           'customerName': customerName,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         // This assumes your backend returns a JSON like: { "data": { "clientSecret": "..." } } for callable functions
//         // or { "clientSecret": "..." } for a direct HTTPS request. Adjust as needed.
//         return data['clientSecret'] ?? data['data']?['clientSecret'];
//       } else {
//         _log.e('Backend failed to create payment intent. Status: ${response.statusCode}, Body: ${response.body}');
//         return null;
//       }
//     } catch (e) {
//       _log.e('Error calling backend for payment intent: $e');
//       return null;
//     }
//   }
// }


