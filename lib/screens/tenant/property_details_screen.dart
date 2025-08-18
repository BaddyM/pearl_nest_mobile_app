import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/apis/property_interactions_service.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_event.dart';
import 'package:pearlnest/screens/chat/admin_list_screen.dart';
import 'package:pearlnest/screens/tenant/payment_screen.dart';

class Review {
  final String id;
  final double rating;
  final String propertyName;
  final String propertyId;
  final String userName;
  final String review;
  

  Review({
    required this.id,
    required this.userName,
    required this.propertyName,
    required this.propertyId,
    required this.rating,
    required this.review,
  });

  // Factory constructor to create Review from API response
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      userName: json['user']?['name']?.toString() ?? 'Anonymous',
      rating: (json['stars']?.toDouble() ?? 0.0),
      review: json['review']?.toString() ?? '',
      propertyName: json['property']?['propertyName']?.toString() ?? 'Unknown Property',
      propertyId: json['property']?['id']?.toString() ?? '',
    );
  }
}

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  final User user;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
    required this.user,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  List<Review> _reviews = [];
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _showAllReviews = false;

  // Booking-related state
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  late BookingBloc _bookingBloc;

  // Pending booking state
  List<Booking> _pendingBookings = [];
  Booking? _pendingBookingForProperty;
  bool _isLoadingPendingBookings = true;

  // API data state
  int _viewsCount = 0;
  int _sharesCount = 0;
  int _likesCount = 0;
  bool _isLoadingStats = false; // Changed to false since we have embedded data

  //Get Role
  Future<Object?>? fetchRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    return role;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    _isFavorite = _isPropertyFavorited();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Initialize booking bloc
    _bookingBloc = context.read<BookingBloc>();

    // Initialize stats from embedded data
    _initializeStatsFromEmbeddedData();

    // Load data from APIs
    _loadPropertyData();
  }

  // Helper to get full image URL
  String _getFullImageUrl(String url) {
    if (url.isEmpty || url == 'undefined' || url == 'null' || url.contains('undefined') || url.contains('null')) {
      return '';
    }

    if (url.contains(',')) {
      final urls = url.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'undefined' && e != 'null' && !e.contains('undefined') && !e.contains('null')).toList();
      if (urls.isNotEmpty) {
        url = urls.first;
      } else {
        return '';
      }
    }

    if (url.isEmpty || url == 'undefined' || url == 'null' || url.contains('undefined') || url.contains('null')) {
      return '';
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }

  // Load all property data from APIs
  void _loadPropertyData() async {
    // Increment view counter when property is viewed
    PropertyInteractionsService.incrementViewCounter(widget.property.id);

    // Load reviews
    _loadPropertyReviews();

    // Load pending bookings
    _loadPendingBookings();
  }

  // Initialize stats from embedded property data
  void _initializeStatsFromEmbeddedData() {
    setState(() {
      _viewsCount = widget.property.views.length;
      _sharesCount = widget.property.shares.length;
      _likesCount = widget.property.favourites.length;
      _isLoadingStats = false;
    });
  }

  // Load property reviews from API
  void _loadPropertyReviews() async {
    try {
      final result = await PropertyInteractionsService.getPropertyReviews(widget.property.id);
      if (result['success'] == true) {
        final reviewsData = result['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _reviews = reviewsData.map((reviewJson) => Review.fromJson(reviewJson)).toList();
          });
        }
      } else {
        // Fallback to mock data if API fails
      }
    } catch (e) {
      // Fallback to mock data if API fails
    }
  }



  // Load pending bookings for current user and check if this property has pending booking
  void _loadPendingBookings() async {
    try {
      //debugPrint('📚 Loading pending bookings for property: ${widget.property.id}');
      final pendingBookings = await BookingService.fetchPendingBookings();

      // Check if this specific property has a pending booking
      Booking? pendingBookingForThisProperty;
      try {
        pendingBookingForThisProperty = pendingBookings.firstWhere(
          (booking) => booking.propertyId == widget.property.id,
        );
        //debugPrint('📚 Found pending booking for this property: ${pendingBookingForThisProperty.id}');
      } catch (e) {
        // No pending booking for this property
        //debugPrint('📚 No pending booking found for this property');
      }

      if (mounted) {
        setState(() {
          _pendingBookings = pendingBookings;
          _pendingBookingForProperty = pendingBookingForThisProperty;
          _isLoadingPendingBookings = false;
        });
      }
    } catch (e) {
      //debugPrint('❌ Error loading pending bookings: $e');
      if (mounted) {
        setState(() {
          _pendingBookings = [];
          _pendingBookingForProperty = null;
          _isLoadingPendingBookings = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _pageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Helper method to check if current user has favorited this property
  bool _isPropertyFavorited() {
    return widget.property.favourites.any((favourite) => favourite['userId'] == widget.user.id);
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      if (_isFavorite) {
        widget.user.favoriteProperties.add(widget.property.id);
      } else {
        widget.user.favoriteProperties.remove(widget.property.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, color: AppTheme.primaryblue),
              ),
              SizedBox(width: 12),
              Text(
                'Contact Landlord',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Landlord: ${widget.property.landlordName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, color: AppTheme.primaryblue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          widget.property.landlordPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _makePhoneCall(widget.property.landlordPhone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Call Now',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone call', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showAddReviewDialog() {
    _userRating = 0;
    _reviewController.clear();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.rate_review, color: AppTheme.primaryblue),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Write a Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate this property:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _userRating = index + 1.0;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            index < _userRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your review:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this property...',
                      hintStyle: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryblue),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _reviewController.clear();
                    _userRating = 0;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ),
                ElevatedButton(
                  onPressed: _userRating > 0 && _reviewController.text.trim().isNotEmpty
                      ? () {
                          _submitReview();
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Review',
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitReview() async {
    if (_userRating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a rating and comment', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      // Submit review via API
      final result = await PropertyInteractionsService.addReview(
        propertyId: widget.property.id,
        stars: _userRating.toInt(),
        message: _reviewController.text.trim(),
      );

      if (result['success'] == true) {
        // Add review to local list for immediate UI update
        final newReview = Review(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userName: widget.user.name,
          propertyName: widget.property.title,
          propertyId: widget.property.id,
          rating: _userRating,
          review: _reviewController.text,
        );

        setState(() {
          _reviews.insert(0, newReview);
        });

        _reviewController.clear();
        _userRating = 0;
        Navigator.of(context).pop(); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted successfully!', style: TextStyle(color: AppTheme.whiteColor)),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit review', style: TextStyle(color: AppTheme.whiteColor)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review. Please try again.', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Initiate payment for a pending booking
  Future<void> _initiatePayment() async {
    if (_pendingBookingForProperty == null) {
      CustomSnackBar.showWarning(context, "No pending booking found for this property.");

      return;
    }

    // First show dialog to get payment amount
    final double? paymentAmount = await _showPaymentAmountDialog();

    if (paymentAmount == null) {
      // User cancelled the dialog
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.getCardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryblue),
                SizedBox(height: 20),
                Text(
                  'Setting up payment...',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      );

      //debugPrint('💳 Initiating payment for booking: ${_pendingBookingForProperty!.id} with amount: UGX ${NumberFormat('#,##0').format(paymentAmount)}');

      // Debug user ID to identify the issue
      //debugPrint('🔍 User ID validation:');
      //debugPrint('   - widget.user.id: "${widget.user.id}"');
      //debugPrint('   - widget.user.id.isEmpty: ${widget.user.id.isEmpty}');
      //debugPrint('   - widget.user.id.length: ${widget.user.id.length}');
      //debugPrint('   - widget.user.name: "${widget.user.name}"');
      //debugPrint('   - widget.user.email: "${widget.user.email}"');

      // Validate user ID before making payment request
      if (widget.user.id.isEmpty) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        //debugPrint('❌ User ID is empty - attempting to get from AuthService');

        // Try to get user ID from AuthService as fallback
        final currentUserId = await AuthService.getUserId();
        //debugPrint('🔍 AuthService.getUserId() returned: "$currentUserId"');

        if (currentUserId == null || currentUserId.isEmpty) {
          _showPaymentError('User session invalid. Please logout and login again.');
          return;
        }

        //debugPrint('✅ Using fallback user ID: $currentUserId');

        // Show loading dialog again
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryblue),
                  SizedBox(height: 20),
                  Text(
                    'Setting up payment...',
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // Create payment with the fallback user ID
        final paymentResult = await PaymentService.createPayment(
          userId: currentUserId,
          bookingId: _pendingBookingForProperty!.id,
          propertyId: widget.property.id,
          amount: paymentAmount,
        );

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (paymentResult['success'] == true) {
          final String? redirectUrl = paymentResult['redirectUrl'];
          final String? orderTrackingId = paymentResult['orderTrackingId'];
          final String? merchantReference = paymentResult['merchantReference'];

          if (redirectUrl != null && orderTrackingId != null && merchantReference != null) {
            // Navigate to payment screen
            final bool? paymentSuccess = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  redirectUrl: redirectUrl,
                  orderTrackingId: orderTrackingId,
                  merchantReference: merchantReference,
                  propertyTitle: widget.property.title,
                  amount: paymentAmount,
                  user: widget.user,
                ),
              ),
            );

            if (paymentSuccess == true) {
              // Payment completed successfully, reload pending bookings
              _loadPendingBookings();

              // Show success message and navigate to home screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment completed successfully!', style: TextStyle(color: AppTheme.whiteColor)),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              // Navigate back to home screen after a brief delay
              Future.delayed(Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              });
            }
          } else {
            _showPaymentError('Payment setup incomplete. Please try again.');
          }
        } else {
          _showPaymentError(paymentResult['message'] ?? 'Failed to create payment. Please try again.');
        }

        return; // Return early since we handled the payment with fallback ID
      }

      // Create payment with the user-specified amount
      final paymentResult = await PaymentService.createPayment(
        userId: widget.user.id,
        bookingId: _pendingBookingForProperty!.id,
        propertyId: widget.property.id,
        amount: paymentAmount, // Use the user-specified amount instead of widget.property.price
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (paymentResult['success'] == true) {
        final String? redirectUrl = paymentResult['redirectUrl'];
        final String? orderTrackingId = paymentResult['orderTrackingId'];
        final String? merchantReference = paymentResult['merchantReference'];

        if (redirectUrl != null && orderTrackingId != null && merchantReference != null) {
          // Navigate to payment screen
          final bool? paymentSuccess = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                redirectUrl: redirectUrl,
                orderTrackingId: orderTrackingId,
                merchantReference: merchantReference,
                propertyTitle: widget.property.title,
                amount: paymentAmount, // Use the user-specified amount
                user: widget.user,
              ),
            ),
          );

          if (paymentSuccess == true) {
            // Payment completed successfully, reload pending bookings
            _loadPendingBookings();

            // Show success message and navigate to home screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment completed successfully!', style: TextStyle(color: AppTheme.whiteColor)),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            // Navigate back to home screen after a brief delay
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        } else {
          _showPaymentError('Payment setup incomplete. Please try again.');
        }
      } else {
        _showPaymentError(paymentResult['message'] ?? 'Failed to create payment. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      //debugPrint('❌ Payment initiation error: $e');
      _showPaymentError('An error occurred while setting up payment. Please try again.');
    }
  }

  // Show payment error dialog
  void _showPaymentError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Payment Error',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to get payment amount from user
  Future<double?> _showPaymentAmountDialog() async {
    final TextEditingController amountController = TextEditingController();
    final formattedPropertyPrice = NumberFormat('#,##0').format(widget.property.price);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment,
                  color: AppTheme.primaryblue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property: ${widget.property.title}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Full Price: UGX $formattedPropertyPrice',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Enter the amount you want to pay to secure this booking:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    hintText: 'Enter amount (UGX)',
                    prefixText: 'UGX ',
                    prefixStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryblue,
                    ),
                    filled: true,
                    fillColor: AppTheme.getBackgroundColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }

                    final double? amount = double.tryParse(value.trim().replaceAll(',', ''));
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }

                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }

                    if (amount > widget.property.price) {
                      return 'Amount cannot exceed UGX $formattedPropertyPrice';
                    }

                    return null;
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryblue,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can pay any amount up to the full property price to secure your booking.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryblue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final String value = amountController.text.trim().replaceAll(',', '');
                        final double amount = double.parse(value);
                        Navigator.of(context).pop(amount);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showBookingConfirmationDialog() {
    // Local state for the dialog
    DateTime? localCheckInDate = _checkInDate;
    DateTime? localCheckOutDate = _checkOutDate;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: _bookingBloc,
          child: BlocListener<BookingBloc, BookingState>(
            listener: (context, state) {
              if (state is BookingSuccess) {
                Navigator.of(context).pop(); // Close dialog
                _showBookingSuccessBottomSheet(state.bookingData, state.message);
              } else if (state is BookingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: AppTheme.getCardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryblue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.book_online, color: AppTheme.primaryblue),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property details
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.property.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.primaryblue, size: 16),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.property.address,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'UGX${NumberFormat('#,##0').format(widget.property.price)} ${widget.property.priceType}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryblue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Date selection
                        Text(
                          'Select Dates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        SizedBox(height: 12),

                        // Check-in date
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: localCheckInDate ?? DateTime.now().add(Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryblue,
                                      onPrimary: AppTheme.whiteColor,
                                      surface: AppTheme.getCardColor(context),
                                      onSurface: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setDialogState(() {
                                localCheckInDate = picked;
                                // Reset checkout date if it's before the new checkin date
                                if (localCheckOutDate != null && localCheckOutDate!.isBefore(picked)) {
                                  localCheckOutDate = null;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightGreyColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: AppTheme.primaryblue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  localCheckInDate != null ? 'Check-in: ${DateFormat('MMM dd, yyyy').format(localCheckInDate!)}' : 'Select check-in date',
                                  style: TextStyle(
                                    color: localCheckInDate != null ? AppTheme.getTextColor(context) : AppTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Check-out date
                        GestureDetector(
                          onTap: () async {
                            final DateTime minDate = localCheckInDate?.add(Duration(days: 1)) ?? DateTime.now().add(Duration(days: 2));

                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: localCheckOutDate ?? minDate,
                              firstDate: minDate,
                              lastDate: DateTime.now().add(Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryblue,
                                      onPrimary: AppTheme.whiteColor,
                                      surface: AppTheme.getCardColor(context),
                                      onSurface: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setDialogState(() {
                                localCheckOutDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightGreyColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: AppTheme.primaryblue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  localCheckOutDate != null ? 'Check-out: ${DateFormat('MMM dd, yyyy').format(localCheckOutDate!)}' : 'Select check-out date',
                                  style: TextStyle(
                                    color: localCheckOutDate != null ? AppTheme.getTextColor(context) : AppTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (localCheckInDate != null && localCheckOutDate != null) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryblue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  '${localCheckOutDate!.difference(localCheckInDate!).inDays} nights',
                                  style: TextStyle(
                                    color: AppTheme.primaryblue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 16),
                        Text(
                          'Payment is required within 24 hours to secure your booking. Failure to pay will result in the property being made available for other bookings',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                      ),
                    ),
                    BlocBuilder<BookingBloc, BookingState>(
                      builder: (context, state) {
                        final isLoading = state is BookingLoading;
                        final canSubmit = localCheckInDate != null && localCheckOutDate != null && !isLoading;

                        return ElevatedButton(
                          onPressed: canSubmit
                              ? () {
                                  // Update the main state before submitting
                                  setState(() {
                                    _checkInDate = localCheckInDate;
                                    _checkOutDate = localCheckOutDate;
                                  });
                                  _submitBooking();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryblue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                                  ),
                                )
                              : Text(
                                  'Confirm Booking',
                                  style: TextStyle(color: AppTheme.whiteColor),
                                ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Increased the height multipliers to accommodate all content
    final expandedHeight = isVerySmallScreen
        ? screenHeight * 0.65 // Increased from 0.55
        : isSmallScreen
            ? screenHeight * 0.70 // Increased from 0.6
            : 520.0; // Increased from 470.0

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: expandedHeight,
                floating: false,
                pinned: true,
                snap: false,
                backgroundColor: AppTheme.getBackgroundColor(context),
                elevation: 0,
                automaticallyImplyLeading: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      _buildFixedImageSection(),
                      Expanded(
                        // Added Expanded to prevent overflow
                        child: _buildPropertyHeader(),
                      ),
                    ],
                  ),
                  collapseMode: CollapseMode.pin,
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(isSmallScreen ? 44.0 : 48.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryblue,
                      indicatorWeight: isSmallScreen ? 2 : 3,
                      labelColor: AppTheme.primaryblue,
                      unselectedLabelColor: AppTheme.getSecondaryTextColor(context),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      tabs: [
                        Tab(text: 'About'),
                        Tab(text: 'Gallery'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(),
              _buildGalleryTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFixedImageSection() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    final imageHeight = isVerySmallScreen
        ? screenHeight * 0.35
        : isSmallScreen
            ? screenHeight * 0.4
            : 300.0;

    final horizontalPadding = screenWidth * 0.04;
    final bottomPadding = isSmallScreen ? 12.0 : 20.0;
    final fabSize = isSmallScreen ? 48.0 : 56.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    final borderRadius = isSmallScreen ? 16.0 : 20.0;

    final images = widget.property.images.isNotEmpty ? widget.property.images : ['assets/images/img1.jpg'];

    return SizedBox(
      height: imageHeight,
      child: Stack(
        children: [
          ClipPath(
            clipper: HeartCutoutClipper(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {});
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: widget.property.images.isNotEmpty
                        ? Image.network(
                            _getFullImageUrl(images[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(borderRadius),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.lightGreyColor,
                                      AppTheme.primaryblue.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.primaryblue,
                                    size: isSmallScreen ? 40 : 50,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderRadius),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryblue.withValues(alpha: 0.1),
                                  AppTheme.primaryblue.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.home_rounded,
                                color: AppTheme.primaryblue,
                                size: isSmallScreen ? 40 : 50,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          ClipPath(
            clipper: HeartCutoutClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.getTextColor(context).withValues(alpha: 0.3),
                    Colors.transparent,
                    AppTheme.getTextColor(context).withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: bottomPadding,
            right: horizontalPadding,
            child: Container(
              width: fabSize,
              height: fabSize,
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_outline,
                  color: _isFavorite ? Colors.red : AppTheme.getSecondaryTextColor(context),
                  size: iconSize,
                ),
                onPressed: _toggleFavorite,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (widget.property.isFeatured)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryblue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Featured',
                        style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyHeader() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = isSmallScreen ? 8.0 : 16.0;
    final spacing = isSmallScreen ? 6.0 : 12.0;
    final titleFontSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 22.0;
    final priceFontSize = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 22.0
            : 28.0;
    final tagFontSize = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 9.0
            : 11.0;
    final addressFontSize = isSmallScreen ? 12.0 : 14.0;
    final priceTypeFontSize = isSmallScreen ? 11.0 : 14.0;
    final ratingFontSize = isSmallScreen ? 11.0 : 13.0;
    final reviewCountFontSize = isSmallScreen ? 9.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
                  ),
                  child: Text(
                    widget.property.propertyTypeString,
                    style: TextStyle(
                      fontSize: tagFontSize,
                      color: AppTheme.primaryblue,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Spacer(),

              //rating and review count  

              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
              //   decoration: BoxDecoration(
              //     color: Colors.amber.withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.star, color: Colors.amber, size: isSmallScreen ? 10 : 14),
              //       SizedBox(width: 2),
              //       Text(
              //         '${widget.property.rating}',
              //         style: TextStyle(
              //           fontSize: ratingFontSize,
              //           fontWeight: FontWeight.bold,
              //           color: AppTheme.getTextColor(context),
              //         ),
              //       ),
              //       Text(
              //         ' (${_reviews.length})',
              //         style: TextStyle(
              //           fontSize: reviewCountFontSize,
              //           color: AppTheme.getSecondaryTextColor(context),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            widget.property.title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
              height: 1.2,
            ),
            maxLines: isVerySmallScreen
                ? 1
                : isSmallScreen
                    ? 2
                    : 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing * 0.5),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryblue, size: isSmallScreen ? 12 : 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.property.address,
                  style: TextStyle(
                    fontSize: addressFontSize,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'UGX${NumberFormat('#,##0').format(widget.property.price)}',
                        style: TextStyle(
                          fontSize: priceFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryblue,
                        ),
                      ),
                    ),
                    Text(
                      widget.property.priceType,
                      style: TextStyle(
                        fontSize: priceTypeFontSize,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.property.isVerified) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryblue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppTheme.whiteColor, size: isSmallScreen ? 10 : 14),
                      SizedBox(width: 2),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontSize: tagFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    final bottomPadding = isVerySmallScreen
        ? 80.0
        : isSmallScreen
            ? 90.0
            : 100.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        children: [
          _buildQuickStats(),
          _buildPropertyDetails(),
          _buildDescription(),
          _buildAmenities(),
          _buildLocationSection(),
          _buildLandlordInfo(),
          _buildSafetyFeatures(),
          _buildNearbyPlaces(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Responsive margins and spacing
    final margin = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 16.0
            : 20.0;
    final spacing = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 12.0;

    return Container(
      margin: EdgeInsets.all(margin),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.visibility,
              title: 'Views',
              value: _isLoadingStats ? '...' : _formatStatNumber(_viewsCount),
              color: Colors.blue,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              title: 'Likes',
              value: _formatStatNumber(_likesCount),
              color: Colors.red,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatCard(
              icon: Icons.share,
              title: 'Shares',
              value: _isLoadingStats ? '...' : _formatStatNumber(_sharesCount),
              color: Colors.green,
              onTap: _shareProperty,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule,
              title: 'Available',
              value: widget.property.availabilityStatus == AvailabilityStatus.availableNow ? 'Now' : 'Later',
              color: AppTheme.primaryblue,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format large numbers (e.g., 1500 -> 1.5k)
  String _formatStatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSmallScreen,
    required bool isVerySmallScreen,
    VoidCallback? onTap,
  }) {
    final cardPadding = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 12.0
            : 16.0;
    final iconContainerPadding = isVerySmallScreen
        ? 4.0
        : isSmallScreen
            ? 6.0
            : 8.0;
    final iconSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 20.0;
    final borderRadius = isVerySmallScreen ? 12.0 : 16.0;
    final spacing = isVerySmallScreen
        ? 4.0
        : isSmallScreen
            ? 6.0
            : 8.0;

    final valueFontSize = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 14.0
            : 16.0;
    final titleFontSize = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 9.0
            : 10.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconContainerPadding),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(height: spacing),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
                maxLines: 1,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: AppTheme.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyFeatures() {
    final safetyFeatures = [
      {'icon': Icons.security, 'name': '24/7 Security', 'available': true},
      {'icon': Icons.local_fire_department, 'name': 'Fire Safety', 'available': true},
      {'icon': Icons.videocam, 'name': 'CCTV', 'available': true},
      {'icon': Icons.emergency, 'name': 'Emergency Exit', 'available': true},
      {'icon': Icons.lock, 'name': 'Secure Entry', 'available': true},
      {'icon': Icons.medical_services, 'name': 'First Aid', 'available': false},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield, color: Colors.orange, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Safety & Security',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...safetyFeatures.map((feature) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: feature['available'] as bool ? AppTheme.primaryblue.withValues(alpha: 0.1) : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['available'] as bool ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: feature['available'] as bool ? AppTheme.getTextColor(context) : AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    feature['available'] as bool ? Icons.check_circle : Icons.cancel,
                    color: feature['available'] as bool ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
                    size: 18,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaces() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Responsive sizing
    final margin = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 16.0
            : 20.0;
    final padding = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 16.0
            : 20.0;
    final borderRadius = isVerySmallScreen ? 12.0 : 16.0;
    final headerSpacing = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 10.0
            : 12.0;
    final sectionSpacing = isVerySmallScreen ? 12.0 : 16.0;

    // Responsive font sizes
    final titleFontSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 20.0;
    final placeFontSize = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 11.0
            : 12.0;
    final distanceFontSize = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 9.0
            : 10.0;

    // Responsive icon sizes
    final headerIconSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 20.0;
    final placeIconSize = isVerySmallScreen
        ? 14.0
        : isSmallScreen
            ? 16.0
            : 18.0; // Reduced icon size
    final iconPadding = isVerySmallScreen ? 6.0 : 8.0;

    // Grid settings - Fixed aspect ratio to give more height
    final crossAxisSpacing = isVerySmallScreen ? 8.0 : 12.0;
    final mainAxisSpacing = isVerySmallScreen ? 8.0 : 12.0;
    final childAspectRatio = isVerySmallScreen
        ? 2.2
        : isSmallScreen
            ? 2.3
            : 2.5; // Reduced for more height
    final gridPadding = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 12.0; // Reduced padding

    final nearbyPlaces = [
      {'icon': Icons.school, 'name': 'University', 'distance': '0.5 km', 'color': Colors.blue},
      {'icon': Icons.local_hospital, 'name': 'Hospital', 'distance': '1.2 km', 'color': Colors.red},
      {'icon': Icons.shopping_cart, 'name': 'Shopping Mall', 'distance': '0.8 km', 'color': Colors.purple},
      {'icon': Icons.train, 'name': 'Metro Station', 'distance': '0.3 km', 'color': Colors.green},
      {'icon': Icons.restaurant, 'name': 'Restaurants', 'distance': '0.2 km', 'color': Colors.orange},
      {'icon': Icons.local_gas_station, 'name': 'Gas Station', 'distance': '0.6 km', 'color': Colors.grey},
    ];

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.place, color: Colors.purple, size: headerIconSize),
              ),
              SizedBox(width: headerSpacing),
              Expanded(
                child: Text(
                  'Nearby Places',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sectionSpacing),

          // Grid of nearby places
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: nearbyPlaces.length,
            itemBuilder: (context, index) {
              final place = nearbyPlaces[index];
              return Container(
                padding: EdgeInsets.all(gridPadding),
                decoration: BoxDecoration(
                  color: (place['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius * 0.75),
                  border: Border.all(
                    color: (place['color'] as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Added for better alignment
                  children: [
                    Icon(
                      place['icon'] as IconData,
                      color: place['color'] as Color,
                      size: placeIconSize,
                    ),
                    SizedBox(width: isVerySmallScreen ? 4.0 : 6.0), // Reduced spacing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            // Changed from FittedBox to Flexible
                            child: Text(
                              place['name'] as String,
                              style: TextStyle(
                                fontSize: placeFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context),
                                height: 1.1, // Reduced line height
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isVerySmallScreen ? 1.0 : 2.0),
                          Flexible(
                            // Added Flexible for distance too
                            child: Text(
                              place['distance'] as String,
                              style: TextStyle(
                                fontSize: distanceFontSize,
                                color: AppTheme.getSecondaryTextColor(context),
                                height: 1.0, // Tight line height
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    final images = widget.property.images;

    final validImages = images.where((image) {
      final fullUrl = _getFullImageUrl(image);
      final isValid = fullUrl.isNotEmpty;
      return isValid;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Gallery',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          validImages.isEmpty
              ? _buildNoImagesPlaceholder()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: validImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _getFullImageUrl(validImages[index]);

                    return GestureDetector(
                      onTap: () {
                        _showImageViewer(validImages, index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppTheme.lightGreyColor,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryblue,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.lightGreyColor,
                                      AppTheme.primaryblue.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.primaryblue,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNoImagesPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryblue.withValues(alpha: 0.1),
            AppTheme.primaryblue.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: AppTheme.primaryblue,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No images available',
              style: TextStyle(
                color: AppTheme.primaryblue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Images will appear here when uploaded',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: Icon(Icons.add, color: AppTheme.primaryblue, size: 18),
                  label: Text(
                    'Write Review',
                    style: TextStyle(
                      color: AppTheme.primaryblue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildReviewsSummary(),
          SizedBox(height: 20),
          ..._reviews.take(_showAllReviews ? _reviews.length : 3).map((review) {
            return _buildReviewCard(review);
          }),
          if (_reviews.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllReviews = !_showAllReviews;
                  });
                },
                child: Text(
                  _showAllReviews ? 'Show Less' : 'Show All Reviews (${_reviews.length})',
                  style: TextStyle(
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = _getFullImageUrl(images[index]);

                  return Center(
                    child: InteractiveViewer(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.lightGreyColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.getSecondaryTextColor(context),
                                    size: 50,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: AppTheme.getSecondaryTextColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyDetails() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.bed,
                  'Bedrooms',
                  '${widget.property.bedrooms}',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDetailItem(
                  Icons.bathtub,
                  'Bathrooms',
                  '${widget.property.bathrooms}',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.square_foot,
                  'Area',
                  '${widget.property.area} sqft',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDetailItem(
                  Icons.local_parking,
                  'Parking',
                  widget.property.amenities.contains('Parking') == true ? 'Available' : 'Not Available',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryblue, size: 20),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.description, color: AppTheme.primaryblue, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'About This Property',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryblue.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              widget.property.description,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildHighlightChip('Move-in Ready', Icons.check_circle, Colors.green),
              SizedBox(width: 8),
              _buildHighlightChip('Furnished', Icons.chair, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Responsive sizing
    final margin = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 14.0
            : 16.0;
    final padding = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 14.0
            : 16.0;
    final borderRadius = isVerySmallScreen ? 10.0 : 12.0;
    final sectionSpacing = isVerySmallScreen ? 6.0 : 8.0;

    // Responsive font sizes
    final titleFontSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 17.0
            : 18.0;
    final amenityFontSize = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 9.0
            : 10.0;

    // Responsive icon size
    final iconSize = isVerySmallScreen
        ? 18.0
        : isSmallScreen
            ? 20.0
            : 25.0;

    // Parse amenities from property data first
    final List<Map<String, dynamic>> amenities = _parseAmenities(widget.property.amenities);

    // Grid settings - Adjust for small screens and number of amenities
    final totalAmenities = amenities.length;
    final crossAxisCount = isVerySmallScreen 
        ? (totalAmenities > 6 ? 3 : 2) // Reduce columns on very small screens
        : (totalAmenities > 8 ? 4 : 3); // Normal screens
    final crossAxisSpacing = isVerySmallScreen ? 6.0 : 8.0;
    final mainAxisSpacing = isVerySmallScreen ? 6.0 : 8.0;
    final childAspectRatio = isVerySmallScreen
        ? 0.85
        : isSmallScreen
            ? 0.87
            : 0.9;
    final itemPadding = isVerySmallScreen ? 6.0 : 8.0;
    final itemBorderRadius = isVerySmallScreen ? 8.0 : 10.0;
    final iconTextSpacing = isVerySmallScreen ? 4.0 : 6.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: sectionSpacing),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              return Container(
                padding: EdgeInsets.all(itemPadding),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(itemBorderRadius),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Icon(
                        amenity['icon'] as IconData,
                        color: AppTheme.primaryblue,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: iconTextSpacing),
                    Flexible(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          amenity['name'] as String,
                          style: TextStyle(
                            fontSize: amenityFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                            height: 1.0, // Tight line height
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, // Force single line on small screens
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              // TextButton.icon(
              //   onPressed: _openMap,
              //   icon: Icon(Icons.map, color: AppTheme.primaryblue, size: 18),
              //   label: Text(
              //     'View on Map',
              //     style: TextStyle(
              //       color: AppTheme.primaryblue,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryblue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.property.address,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.lightGreyColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.property.propertyMap != null && widget.property.propertyMap!.isNotEmpty ? _buildMapWebView() : _buildMapPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            //debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            //debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            //debugPrint('Map loading error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_createMapHtml());

    return WebViewWidget(controller: controller);
  }

  Widget _buildMapPlaceholder() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: AppTheme.lightGreyColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: AppTheme.greyColor,
                ),
                SizedBox(height: 8),
                Text(
                  'Map View',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openMap,
              child: Container(),
            ),
          ),
        ),
      ],
    );
  }

  String _createMapHtml() {
    String iframeContent = widget.property.propertyMap ?? '';

    // Clean up the iframe content if needed
    if (!iframeContent.startsWith('<iframe')) {
      // If it's just the src URL, wrap it in iframe tags
      if (iframeContent.contains('google.com/maps/embed')) {
        iframeContent = '<iframe src="$iframeContent" width="100%" height="100%" style="border:0;" allowfullscreen="" loading="lazy"></iframe>';
      }
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { 
                margin: 0; 
                padding: 0; 
                overflow: hidden;
                background-color: #f5f5f5;
            }
            iframe { 
                width: 100%; 
                height: 100vh; 
                border: none; 
                display: block;
            }
        </style>
    </head>
    <body>
        $iframeContent
    </body>
    </html>
    ''';
  }

  Widget _buildLandlordInfo() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Owner',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                ),
                child: widget.property.profilePicture != null || widget.property.profilePicture!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          cacheManager: DefaultCacheManager(),
                          imageUrl: _getFullImageUrl(widget.property.profilePicture!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.primaryblue,
                        size: 30,
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.landlordName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Property Owner',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     Icon(Icons.star, color: Colors.amber, size: 16),
                    //     SizedBox(width: 4),
                    //     Text(
                    //       '4.8',
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.bold,
                    //         color: AppTheme.getTextColor(context),
                    //       ),
                    //     ),
                    //     Text(
                    //       ' (127 reviews)',
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         color: AppTheme.getSecondaryTextColor(context),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callLandlord,
                  icon: Icon(Icons.phone, size: 18),
                  label: Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    foregroundColor: AppTheme.whiteColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              FutureBuilder(
                  future: fetchRole(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasData && snapshot.data == "TENANT") {
                      return Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _messageAdmin,
                          icon: Icon(Icons.message, size: 18),
                          label: Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryblue,
                            side: BorderSide(color: AppTheme.primaryblue),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox();
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSummary() {
    if (_reviews.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            SizedBox(height: 12),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Be the first to write a review!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox();

    // return Container(
    //   padding: EdgeInsets.all(20),
    //   decoration: BoxDecoration(
    //     color: AppTheme.getCardColor(context),
    //     borderRadius: BorderRadius.circular(16),
    //     boxShadow: [
    //       BoxShadow(
    //         color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
    //         blurRadius: 10,
    //         offset: Offset(0, 2),
    //       ),
    //     ],
    //   ),
    //   child: Row(
    //     children: [
    //       Expanded(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Row(
    //               children: [
    //                 Icon(Icons.star, color: Colors.amber, size: 24),
    //                 SizedBox(width: 8),
    //                 Text(
    //                   '${widget.property.rating}',
    //                   style: TextStyle(
    //                     fontSize: 24,
    //                     fontWeight: FontWeight.bold,
    //                     color: AppTheme.getTextColor(context),
    //                   ),
    //                 ),
    //                 Text(
    //                   ' out of 5',
    //                   style: TextStyle(
    //                     fontSize: 16,
    //                     color: AppTheme.getSecondaryTextColor(context),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             SizedBox(height: 4),
    //             Text(
    //               '${_reviews.length} review${_reviews.length != 1 ? 's' : ''}',
    //               style: TextStyle(
    //                 fontSize: 14,
    //                 color: AppTheme.getSecondaryTextColor(context),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //       Column(
    //         crossAxisAlignment: CrossAxisAlignment.end,
    //         children: [
    //           for (int i = 5; i >= 1; i--)
    //             Padding(
    //               padding: EdgeInsets.symmetric(vertical: 2),
    //               child: Row(
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: [
    //                   Text(
    //                     '$i',
    //                     style: TextStyle(
    //                       fontSize: 12,
    //                       color: AppTheme.getSecondaryTextColor(context),
    //                     ),
    //                   ),
    //                   SizedBox(width: 8),
    //                   Container(
    //                     width: 80,
    //                     height: 6,
    //                     decoration: BoxDecoration(
    //                       color: AppTheme.lightGreyColor,
    //                       borderRadius: BorderRadius.circular(3),
    //                     ),
    //                     child: FractionallySizedBox(
    //                       alignment: Alignment.centerLeft,
    //                       widthFactor: _getStarPercentage(i),
    //                       child: Container(
    //                         decoration: BoxDecoration(
    //                           color: Colors.amber,
    //                           borderRadius: BorderRadius.circular(3),
    //                         ),
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //         ],
    //       ),
    //     ],
    //   ),
    // );
  }

  double _getStarPercentage(int stars) {
    if (_reviews.isEmpty) return 0.0;
    int count = _reviews.where((review) => review.rating == stars).length;
    return count / _reviews.length;
  }

  Widget _buildReviewCard(Review review) {
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        SizedBox(width: 8),
                       
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            review.review,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  /// Parse amenities and return list with icons
  List<Map<String, dynamic>> _parseAmenities(dynamic amenitiesData) {
    List<String> amenityNames = [];
    
    if (amenitiesData is String) {
      // If it's a string, split by comma
      if (amenitiesData.isNotEmpty) {
        amenityNames = amenitiesData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } else if (amenitiesData is List) {
      // If it's already a list, convert to strings
      amenityNames = amenitiesData
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    
    // If no amenities, return a default set with appropriate message
    if (amenityNames.isEmpty) {
      return [
        {'icon': Icons.info_outline, 'name': 'No amenities listed'},
      ];
    }
    
    return amenityNames.map((name) {
      return {
        'icon': _getAmenityIcon(name),
        'name': name,
      };
    }).toList();
  }

  /// Get appropriate icon for amenity name
  IconData _getAmenityIcon(String amenityName) {
    final lowerName = amenityName.toLowerCase();
    
    // Map amenity names to icons based on your actual data
    if (lowerName.contains('wifi') || lowerName.contains('internet')) {
      return Icons.wifi;
    } else if (lowerName.contains('laundry') || lowerName.contains('washing')) {
      return Icons.local_laundry_service;
    } else if (lowerName.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowerName.contains('ac') || lowerName.contains('air condition') || lowerName.contains('cooling')) {
      return Icons.ac_unit;
    } else if (lowerName.contains('gym') || lowerName.contains('fitness')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('pool') || lowerName.contains('swimming')) {
      return Icons.pool;
    } else if (lowerName.contains('security')) {
      return Icons.security;
    } else if (lowerName.contains('elevator') || lowerName.contains('lift')) {
      return Icons.elevator;
    } else if (lowerName.contains('parking')) {
      return Icons.local_parking;
    } else if (lowerName.contains('garage')) {
      return Icons.garage;
    } else if (lowerName.contains('balcony')) {
      return Icons.balcony;
    } else if (lowerName.contains('garden') || lowerName.contains('landscap')) {
      return Icons.park;
    } else if (lowerName.contains('pet') || lowerName.contains('animal') || lowerName.contains('friendly')) {
      return Icons.pets;
    } else if (lowerName.contains('compound')) {
      return Icons.home_work;
    } else if (lowerName.contains('heating') || lowerName.contains('heat')) {
      return Icons.thermostat;
    } else if (lowerName.contains('fireplace')) {
      return Icons.fireplace;
    } else if (lowerName.contains('laundry')) {
      return Icons.local_laundry_service;
    } else {
      // Default icon for unknown amenities
      return Icons.check_circle_outline;
    }
  }

  Widget _buildFloatingActionButtons() {
    // Check if this property has a pending booking
    final hasPendingBooking = _pendingBookingForProperty != null;

    // Check if property is available for booking
  final isPropertyAvailable = widget.property.status == PropertyStatus.available;
  


    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryblue),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.getCardColor(context),
            ),
            child: IconButton(
              onPressed: _showContactDialog,
              icon: Icon(
                Icons.phone,
                color: AppTheme.primaryblue,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoadingPendingBookings || !isPropertyAvailable
                  ? null
                  : hasPendingBooking
                      ? _initiatePayment
                      : _showBookingConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoadingPendingBookings || !isPropertyAvailable
                    ? Colors.grey
                    : hasPendingBooking
                        ? AppTheme.primaryblue
                        : AppTheme.primaryblue,
                foregroundColor: AppTheme.whiteColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: (hasPendingBooking ? AppTheme.primaryblue : AppTheme.primaryblue).withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasPendingBooking ? Icons.payment : Icons.book_online,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    hasPendingBooking ? 'Complete Payment' : isPropertyAvailable ? 'Book Now' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening map for ${widget.property.address}',
          style: TextStyle(color: AppTheme.lightGreyColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 500),
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _callLandlord() async {
    final phoneNumber = widget.property.landlordPhone;
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open phone dialer', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _messageAdmin() async {
    // Initialize chat and navigate to admin list screen
    final chatBloc = context.read<ChatBloc>();

    // Initialize chat if not already done
    chatBloc.add(const ChatInitialize());

    // Navigate to admin list screen instead of direct chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminListScreen(
          user: widget.user,
          propertyTitle: widget.property.title,
        ),
      ),
    );
  }

  void _submitBooking() {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both check-in and check-out dates'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Format dates as ISO 8601 strings for API
    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);
    final checkOutFormatted = DateFormat('yyyy-MM-dd').format(_checkOutDate!);

    _bookingBloc.add(BookingCreateRequested(
      propertyId: widget.property.id,
      checkInDate: checkInFormatted,
      checkOutDate: checkOutFormatted,
    ));
  }

  void _showBookingSuccessBottomSheet(Map<String, dynamic> bookingData, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          // isDismissible: true,
          // enableDrag: true,
          // backgroundColor: Colors.transparent,
          // builder: (context) => SingleChildScrollView(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context), // Changed from green to orange to indicate pending
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions, // Changed from check to pending icon
                      color: AppTheme.whiteColor,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Booking Created!', // Changed from "Booking Successful"
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your booking has been created and is pending payment. Complete the payment to secure your reservation as you will receive a call from us.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Add payment reminder container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getCardColor(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: AppTheme.getTextColor(context),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment required to complete your booking',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.getTextColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  if (_checkInDate != null && _checkOutDate != null) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Check-in',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_checkInDate!),
                                style: TextStyle(
                                  color: AppTheme.primaryblue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Check-out',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_checkOutDate!),
                                style: TextStyle(
                                  color: AppTheme.primaryblue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close bottom sheet
                      setState(() {
                        _checkInDate = null;
                        _checkOutDate = null;
                      });
                      _bookingBloc.add(BookingReset());

                      // Refresh pending bookings to update the UI
                      _loadPendingBookings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getCardColor(context), // Changed to orange to indicate next action is payment
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      'Proceed to Payment', // Changed button text to be more actionable
                      style: TextStyle(
                        color: AppTheme.primaryblue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // child: Container(
            // padding: const EdgeInsets.all(24),
            // decoration: BoxDecoration(
            //   color: AppTheme.getCardColor(context),
            //   borderRadius: BorderRadius.circular(24),
            //   ),
            // ),
          ),
        );
      },
    );
  }

  // Handle property sharing
  void _shareProperty() async {
    try {
      // Increment share counter
      await PropertyInteractionsService.incrementShareCounter(widget.property.id);

      // Update local count
      setState(() {
        _sharesCount++;
      });

      // Share the property using the system share functionality
      // You can add share functionality here if needed

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property shared successfully!', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: AppTheme.primaryblue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share property', style: TextStyle(color: AppTheme.whiteColor)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class HeartCutoutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(20),
      ),
    );

    final cutoutSize = 70.0;
    final cutoutPath = Path();
    cutoutPath.addOval(
      Rect.fromLTWH(
        size.width - cutoutSize - 10,
        size.height - cutoutSize - 10,
        cutoutSize,
        cutoutSize,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
