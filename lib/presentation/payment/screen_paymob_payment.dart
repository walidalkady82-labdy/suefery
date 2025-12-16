import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScreenPaymobPayment extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl; // The callback URL you set in Paymob Dashboard

  const ScreenPaymobPayment({
    super.key,
    required this.paymentUrl,
    // Paymob defaults often look like: https://accept.paymobsolutions.com/api/acceptance/post_pay
    // Or strictly your own: https://suefery.com/payment_callback
    this.redirectUrl = 'https://suefery.com/payment_callback', 
  });

  @override
  State<ScreenPaymobPayment> createState() => _ScreenPaymobPaymentState();
}

class _ScreenPaymobPaymentState extends State<ScreenPaymobPayment> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // --- DETECT REDIRECT ---
            // Paymob appends query params to your redirect URL
            // e.g. .../payment_callback?success=true&pending=false...
            if (request.url.startsWith(widget.redirectUrl)) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleRedirect(String url) {
    final uri = Uri.parse(url);
    // Paymob returns 'success' as string 'true' or 'false'
    final isSuccess = uri.queryParameters['success'] == 'true';
    final isPending = uri.queryParameters['pending'] == 'true';

    if (isSuccess && !isPending) {
      // Payment Successful
      Navigator.pop(context, true);
    } else {
      // Payment Failed or Pending
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}