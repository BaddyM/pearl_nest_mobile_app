import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:pearlnest/blocs/booking/booking_bloc.dart";
import "package:pearlnest/blocs/booking/booking_event.dart";
import "package:pearlnest/blocs/booking/booking_state.dart";
import "package:pearlnest/models/property.dart";
import "package:pearlnest/screens/tenant/favorites_screen.dart";
import "package:pearlnest/widgets/app_theme.dart";
import "package:url_launcher/url_launcher.dart";

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

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
          height: MediaQuery.of(context).size.height * 0.73,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              child: BlocConsumer<BookingBloc, BookingState>(builder: (context, state) {
                if (state is BookingLoading) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGreen,
                    ),
                  );
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
                          if (property != null) {
                            final amount = state.bookings[index].payments.fold(0 as num, (sum, item) => item["paymentStatus"] == "APPROVED" ? sum + item["amount"] : sum + 0);
                            double propertyPrice = property.price;
                            double balance = propertyPrice - amount.toDouble();
                            return Container(
                              margin: EdgeInsets.only(bottom: 20),
                              child: PropertyCard(
                                bookingId: bookingId,
                                isBooking: balance == 0.0 ? false : true,
                                balance: balance.toInt(),
                                paid: amount.toInt(),
                                property: property,
                                onTap: () {},
                                onFavorite: () {},
                                isFavorite: false,
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
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive['borderRadius'] - 4),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: AppTheme.primaryblue,
                    size: responsive['isSmallScreen'] ? 20 : 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
