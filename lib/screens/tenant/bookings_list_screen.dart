import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:pearlnest/blocs/booking/booking_bloc.dart";
import "package:pearlnest/blocs/booking/booking_event.dart";
import "package:pearlnest/blocs/booking/booking_state.dart";
import "package:pearlnest/models/booking.dart";
import "package:pearlnest/models/property.dart";
import "package:pearlnest/models/user.dart";
import "package:pearlnest/screens/tenant/favorites_screen.dart";
import "package:pearlnest/screens/tenant/home_screen.dart";
import "package:pearlnest/screens/tenant/refund_request_screen.dart";
import "package:pearlnest/widgets/app_theme.dart";
import "package:pearlnest/widgets/empty_properties.dart";
import "package:pearlnest/widgets/loading_widget.dart";
import "package:url_launcher/url_launcher.dart";

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key, required this.user});
  final User user;

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  bool _isGridView = false;

  Map<String, dynamic> _getResponsiveValues(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;

    return {
      'isSmallScreen': isSmallScreen,
      'isVerySmallScreen': isVerySmallScreen,
      'isNarrowScreen': isNarrowScreen,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'horizontalPadding': isNarrowScreen
          ? 12.0
          : isSmallScreen
              ? 16.0
              : 20.0,
      'verticalPadding': isSmallScreen ? 12.0 : 16.0,
      'titleFontSize': isVerySmallScreen
          ? 22.0
          : isSmallScreen
              ? 25.0
              : 28.0,
      'subtitleFontSize': isSmallScreen ? 12.0 : 14.0,
      'cardSpacing': isSmallScreen ? 12.0 : 16.0,
      'borderRadius': isSmallScreen ? 12.0 : 16.0,
    };
  }

  Future<void> launchMyUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    try {
      // canLaunchUrl checks if the device has an app that can handle the request
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      // You can use the showErrorDialog we created earlier here!
      print("Error launching URL: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(FetchBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: _buildBody(),
    );
  }

  Future<void> onRefresh() async {
    context.read<BookingBloc>().add(FetchBookings());
  }

  Widget _buildBody() {
    return SafeArea(
        child: Column(
      children: [
        _buildHeader(),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              child: BlocConsumer<BookingBloc, BookingState>(builder: (context, state) {
                if (state is BookingLoading) {
                  return LoadingWidget();
                } else if (state is BookingLoaded) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                        itemCount: state.bookings.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          Property? property = state.bookings[index].property;
                          String? bookingId = state.bookings[index].id;
                          Booking booking = state.bookings[index];
                          if (property != null) {
                            final successfulPayments = booking.payments.where((item) {
                              final paymentStatus = item["paymentStatus"]?.toString().toUpperCase();
                              return paymentStatus == "APPROVED" || paymentStatus == "BOOKED";
                            }).toList();
                            final amount = successfulPayments.fold<num>(0, (sum, item) => sum + ((item["amount"] as num?) ?? 0));
                            final totalDue = booking.totalAmount ?? (property.deposit != 0 ? property.deposit : property.price);
                            final initialDue = booking.amount ?? totalDue;
                            final balance = amount == 0 ? initialDue - amount.toDouble() : totalDue - amount.toDouble();
                            return Container(
                              margin: EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PropertyCard(
                                    bookingId: bookingId,
                                    isBooking: balance == 0.0 ? false : true,
                                    balance: balance.toInt(),
                                    paid: amount.toInt(),
                                    property: property,
                                    onTap: () {},
                                    onFavorite: () {},
                                    isFavorite: false,
                                    status: booking.status,
                                    booking: booking,
                                  ),
                                  if (successfulPayments.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.currency_exchange),
                                        label: const Text('Request a refund'),
                                        onPressed: () {
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => RefundRequestScreen(
                                              propertyName: booking.propertyTitle,
                                              payments: successfulPayments,
                                            ),
                                          ));
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          } else {
                            return SizedBox();
                          }
                        }),
                  );
                } else if (state is PaymentLink) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Processing payment..."),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              context.read<BookingBloc>().add(FetchBookings()); // Closes the dialog
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is BookingEmpty) {
                  return EmptyPropertiesWidget(
                    title: "No recent bookings found",
                    message: "We couldn't find any recent bookings, kindly go to the properties page and book a property.",
                    buttonText: "Home",
                    onButtonPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen(user: widget.user)), (route) => false);
                    },
                  );
                } else {
                  return SizedBox();
                }
              }, listener: (context, state) {
                if (state is BookingError) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('An Error Occurred'),
                      content: Text(state.message),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<BookingBloc>().add(FetchBookings()); // Closes the dialog
                          },
                          child: const Text('Okay'),
                        ),
                      ],
                    ),
                  );
                } else if (state is PaymentLink) {
                  launchMyUrl(state.paymentLink.trim());
                } else if (state is BookingCancelled) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                              const SizedBox(height: 16),
                              const Text(
                                "Booking Cancelled",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Your booking has been successfully cancelled. A confirmation email has been sent to you.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryblue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: () {
                                    context.read<BookingBloc>().add(FetchBookings());
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Got it", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildHeader() {
    final responsive = _getResponsiveValues(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive['horizontalPadding'],
        vertical: responsive['verticalPadding'],
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.getBackgroundColor(context),
            AppTheme.primaryblue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(responsive['borderRadius'] + 9),
          bottomRight: Radius.circular(responsive['borderRadius'] + 9),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              BackButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomeScreen(user: widget.user)),
                    (route) => false,
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Recent Bookings',
                        style: TextStyle(
                          fontSize: responsive['titleFontSize'],
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
