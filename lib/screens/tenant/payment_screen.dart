import 'package:flutter/material.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/widgets/refund_policy.dart';

class PaymentScreen extends StatefulWidget {
  final String redirectUrl;
  final String orderTrackingId;
  final String merchantReference;
  final double amount;
  final String propertyTitle;
  final User user;
  final String bookingStatus;

  const PaymentScreen({
    super.key,
    required this.redirectUrl,
    required this.orderTrackingId,
    required this.merchantReference,
    required this.amount,
    required this.propertyTitle,
    required this.user,
    this.bookingStatus = 'PENDING',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _completionDialogShown = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterPayment',
        onMessageReceived: (JavaScriptMessage message) {
          //debugPrint('💳 JavaScript message received: ${message.message}');
          _handleJavaScriptMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            //debugPrint('💳 Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            //debugPrint('💳 Page finished loading: $url');
            if (mounted) setState(() => _isLoading = false);

            // Inject JavaScript to detect button clicks
            _injectJavaScript();

            // Check if we're on success or failure page
            _checkPaymentCompletion(url);
          },
          onWebResourceError: (WebResourceError error) {
            //debugPrint('💳 WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            //debugPrint('💳 Navigation request: ${request.url}');

            // Handle deep links
            if (request.url.startsWith('pearlnest://')) {
              _handleDeepLink(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Load the payment URL
    _controller.loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _checkPaymentCompletion(String url) {
    // Check if the URL indicates payment completion
    if (url.contains('success') || url.contains('completed') || url.contains('done')) {
      _showPaymentCompletionDialog(true);
    } else if (url.contains('cancel') || url.contains('failed') || url.contains('error')) {
      _showPaymentCompletionDialog(false);
    }
  }

  void _injectJavaScript() {
    // Inject JavaScript to detect "Go to App" button clicks and other success indicators
    _controller.runJavaScript('''
      (function() {
        // Function to send message to Flutter
        function sendToFlutter(message) {
          if (window.FlutterPayment && window.FlutterPayment.postMessage) {
            window.FlutterPayment.postMessage(message);
          }
        }
        
        // Look for common success page indicators
        setTimeout(function() {
          // Check for success text
          var successTexts = ['payment has been successfully received', 'payment successful', 'transaction successful', 'payment completed'];
          var pageText = document.body.innerText.toLowerCase();
          
          for (var i = 0; i < successTexts.length; i++) {
            if (pageText.includes(successTexts[i])) {
              sendToFlutter('payment_success_detected');
              break;
            }
          }
          
          // Look for "Go to App" or similar buttons
          var buttons = document.querySelectorAll('button, a, .btn, [onclick], [href]');
          for (var i = 0; i < buttons.length; i++) {
            var button = buttons[i];
            var buttonText = button.innerText.toLowerCase();
            
            if (buttonText.includes('go to app') ||
                buttonText.includes('return to app') ||
                buttonText.includes('back to app') ||
                buttonText.includes('continue')) {

              button.addEventListener('click', function(e) {
                e.preventDefault();
                sendToFlutter('go_to_app_clicked');
              });
            }
          }
        }, 1000);
      })();
    ''');
  }

  void _handleJavaScriptMessage(String message) {
    //debugPrint('💳 Handling JavaScript message: $message');

    switch (message) {
      case 'payment_success_detected':
        _showPaymentCompletionDialog(true);
        break;
      case 'go_to_app_clicked':
        // Navigate to home screen instead of popping
        _navigateToHomeScreen(true);
        break;
      default:
      //debugPrint('💳 Unknown JavaScript message: $message');
    }
  }

  void _navigateToHomeScreen(bool paymentSuccess) {
    // Navigate to home screen and clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(user: widget.user),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _handleDeepLink(String url) {
    //debugPrint('💳 Handling deep link: $url');

    if (url.contains('success')) {
      _showPaymentCompletionDialog(true);
    } else if (url.contains('cancel') || url.contains('failed')) {
      _showPaymentCompletionDialog(false);
    }
  }

  void _showPaymentCompletionDialog(bool isSuccess) {
    if (!mounted || _completionDialogShown) return;
    _completionDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSuccess ? 'Payment Successful!' : 'Payment Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSuccess ? 'Your payment for ${widget.propertyTitle} has been processed successfully.' : 'Payment could not be completed. Please try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Text(
                          '${ProfileService().currencyConverter(price: widget.amount.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryblue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reference:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.merchantReference,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!isSuccess)
              TextButton(
                onPressed: () {
                  _completionDialogShown = false;
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.primaryblue),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                if (isSuccess) {
                  _navigateToHomeScreen(true); // Navigate to home screen
                } else {
                  Navigator.of(context).pop(false); // Return to previous screen with failure result
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                isSuccess ? 'Continue' : 'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
        title: Text(
          'Complete Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryblue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.getTextColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Complete payment securely to continue',
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount due',
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ProfileService().currencyConverter(price: widget.amount.toInt()),
                            style: const TextStyle(
                              color: AppTheme.primaryblue,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline, color: AppTheme.primaryblue, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      'Secure checkout',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: RefundPolicyNotice(bookingStatus: widget.bookingStatus),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_hasError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 58, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Payment page could not load',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? 'Check your connection and try again.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isLoading = true;
                              });
                              _controller.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  WebViewWidget(controller: _controller),
                if (_isLoading && !_hasError)
                  Container(
                    color: AppTheme.getBackgroundColor(context),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting to secure checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your booking details are being prepared.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel Payment?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          content: Text(
            'Are you sure you want to cancel the payment process? Your booking will remain pending until payment is completed.',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Continue Payment',
                style: TextStyle(color: AppTheme.primaryblue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
