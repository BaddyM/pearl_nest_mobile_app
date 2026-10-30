import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:pearlnest/blocs/booking/booking_bloc.dart";
import "package:pearlnest/blocs/booking/booking_event.dart";
import "package:pearlnest/blocs/booking/booking_state.dart";
import "package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart";
import "package:pearlnest/apis/chat_service.dart";
import "package:pearlnest/screens/chat/new_chat_conversation.dart";
import "package:pearlnest/models/booking.dart";
import "package:pearlnest/models/property.dart";
import "package:pearlnest/models/user.dart";
import "package:pearlnest/screens/tenant/favorites_screen.dart";
import "package:pearlnest/screens/tenant/booking_screen.dart";
import "package:pearlnest/screens/tenant/home_screen.dart";
import "package:pearlnest/screens/tenant/property_details_screen.dart";
import "package:pearlnest/screens/tenant/refund_request_screen.dart";
import "package:pearlnest/widgets/app_theme.dart";
import "package:pearlnest/widgets/empty_properties.dart";
import "package:pearlnest/widgets/loading_widget.dart";
import "package:url_launcher/url_launcher.dart";

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key, required this.user, this.propertyId});
  final User user;
  final String? propertyId;

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  bool _isGridView = false;
  bool _showBookingHistory = false;

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
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the requested app: $e')),
      );
    }
  }

  bool _canContactLandlord(Booking booking) =>
      booking.status == BookingStatus.confirmed &&
      (booking.hasSuccessfulPayment || (booking.amount ?? 0) <= 0);

  bool _canRebook(Property property) =>
      property.availabilityStatus &&
      property.availableUnits > 0 &&
      property.status == PropertyStatus.approved;

  void _rebook(Property property, Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          property: property,
          user: widget.user,
          isViewingRequest: booking.isViewingRequest,
        ),
      ),
    );
  }

  Future<void> _openLandlordChat(Booking booking) async {
    final property = booking.property;
    if (property == null || property.landlordId.isEmpty) return;
    try {
      await ChatService.startPropertyConversation(
        peerId: property.landlordId,
        propertyId: property.id,
      );
      await context.read<NewChatBloc>().socket.connect(widget.user.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NewChatConversation(
          fromUserId: widget.user.id,
          toUserId: property.landlordId,
          userName: property.landlordName,
          userImageUrl: property.profilePicture ??
              property.user?['profilePicture']?.toString(),
          propertyId: property.id,
          propertyTitle: property.title,
          propertyAddress: property.address,
        ),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the landlord chat: $error')),
      );
    }
  }

  Widget _buildLandlordContactActions(Booking booking) {
    final property = booking.property!;
    final phone = property.landlordPhone.trim();
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking approved - contact the property owner',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchMyUrl('tel:$phone'),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                if (phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchMyUrl('sms:$phone'),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Text'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _openLandlordChat(booking),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                  final bookings = state.bookings.where((booking) {
                    final isHistory = booking.status == BookingStatus.cancelled ||
                        booking.status == BookingStatus.completed ||
                        booking.status == BookingStatus.expired;
                    return (_showBookingHistory ? isHistory : !isHistory) &&
                        (widget.propertyId == null ||
                            booking.propertyId == widget.propertyId);
                  }).toList()
                    ..sort((first, second) =>
                        second.createdAt.compareTo(first.createdAt));
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Active'),
                              icon: Icon(Icons.pending_actions),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('History'),
                              icon: Icon(Icons.history),
                            ),
                          ],
                          selected: {_showBookingHistory},
                          onSelectionChanged: (selection) => setState(
                            () => _showBookingHistory = selection.first,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (bookings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Text(
                              _showBookingHistory
                                  ? 'No past bookings yet.'
                                  : 'No active bookings. Your requests will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            itemCount: bookings.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                          Property? property = bookings[index].property;
                          String? bookingId = bookings[index].id;
                          Booking booking = bookings[index];
                          if (property != null) {
                            final successfulPayments = booking.payments.where((item) {
                              final paymentStatus = item["paymentStatus"]?.toString().toUpperCase();
                              return paymentStatus == "APPROVED" || paymentStatus == "BOOKED";
                            }).toList();
                            final amount = successfulPayments.fold<num>(0, (sum, item) => sum + ((item["amount"] as num?) ?? 0));
                            final totalDue = booking.totalAmount ?? (property.deposit != 0 ? property.deposit : property.price);
                            final initialDue = booking.amount ?? totalDue;
                            final balance = (amount == 0
                                    ? initialDue - amount.toDouble()
                                    : totalDue - amount.toDouble())
                                .clamp(0, double.infinity);
                            return Container(
                              margin: EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (booking.landlordRejected)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'The landlord rejected this booking. Any completed payment is guaranteed a full refund. Add your payout details below; the refund is approved automatically and paid manually.',
                                        style: TextStyle(
                                          color: AppTheme.getSecondaryTextColor(context),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  PropertyCard(
                                    bookingId: bookingId,
                                    isBooking: true,
                                    balance: balance.toInt(),
                                    paid: amount.toInt(),
                                    property: property,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PropertyDetailsScreen(
                                            property: property,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                    onFavorite: () {},
                                    isFavorite: false,
                                    status: booking.status,
                                    booking: booking,
                                  ),
                                  if (booking.status == BookingStatus.cancelled ||
                                      booking.status == BookingStatus.expired)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _canRebook(property)
                                              ? () => _rebook(property, booking)
                                              : null,
                                          icon: Icon(
                                            booking.isViewingRequest
                                                ? Icons.event_available_outlined
                                                : Icons.replay_outlined,
                                          ),
                                          label: Text(
                                            _canRebook(property)
                                                ? booking.isViewingRequest
                                                    ? 'Request tour again'
                                                    : 'Book this property again'
                                                : 'Property currently unavailable',
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_canContactLandlord(booking))
                                    _buildLandlordContactActions(booking),
                                  if (successfulPayments.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.currency_exchange),
                                        label: Text(
                                          booking.landlordRejected
                                              ? 'Claim guaranteed refund'
                                              : 'Request a refund',
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => RefundRequestScreen(
                                              propertyName: booking.propertyTitle,
                                              payments: successfulPayments,
                                              landlordRejected: booking.landlordRejected,
                                              administratorReview:
                                                  booking.isViewingRequest,
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
                            },
                          ),
                      ],
                    ),
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
