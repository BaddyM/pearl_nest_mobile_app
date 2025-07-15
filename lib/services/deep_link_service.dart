import 'package:app_links/app_links.dart';
import 'package:pearlnest/apis/payment_service.dart';

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();

  /// Initialize deep link listening
  static void initialize() {
    _appLinks.uriLinkStream.listen((Uri uri) {
      handleDeepLink(uri);
    });
  }

  /// Handle incoming deep links
  static void handleDeepLink(Uri uri) {
    print('Received deep link: $uri');
    
    // Handle payment callback URLs
    if (uri.scheme == 'pearlnest' && uri.host == 'payment') {
      _handlePaymentCallback(uri);
    }
  }

  /// Handle payment callback
  static void _handlePaymentCallback(Uri uri) {
    final paymentId = uri.queryParameters['payment_id'];
    final status = uri.queryParameters['status'];
    
    if (paymentId != null) {
      print('Payment callback received: paymentId=$paymentId, status=$status');
      
      // Check payment status with backend
      PaymentService.checkPaymentStatus(paymentId).then((paymentStatus) {
        print('Payment status check result: $paymentStatus');
        
        // Here you can navigate to appropriate screen or show notification
        // based on payment status
        if (paymentStatus['status'] == 'completed') {
          _showPaymentSuccess();
        } else if (paymentStatus['status'] == 'failed') {
          _showPaymentFailure();
        }
      }).catchError((error) {
        print('Error checking payment status: $error');
        _showPaymentError();
      });
    }
  }

  /// Show payment success notification
  static void _showPaymentSuccess() {
    // This could be improved by using a global navigation key
    // or state management to show notifications/navigate
    print('Payment completed successfully!');
  }

  /// Show payment failure notification
  static void _showPaymentFailure() {
    print('Payment failed!');
  }

  /// Show payment error notification
  static void _showPaymentError() {
    print('Error processing payment callback!');
  }

  /// Get the initial link when app is opened via deep link
  static Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      print('Error getting initial link: $e');
      return null;
    }
  }
}
