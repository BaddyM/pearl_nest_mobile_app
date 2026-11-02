import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:intl/intl.dart";
import "package:pearlnest/apis/booking_service.dart";
import "package:pearlnest/blocs/booking/booking_bloc.dart";
import "package:pearlnest/blocs/booking/booking_event.dart";
import "package:pearlnest/blocs/booking/booking_state.dart";
import "package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart";
import "package:pearlnest/apis/chat_service.dart";
import "package:pearlnest/apis/payment_service.dart";
import "package:pearlnest/screens/chat/new_chat_conversation.dart";
import "package:pearlnest/models/booking.dart";
import "package:pearlnest/models/property.dart";
import "package:pearlnest/models/user.dart";
import "package:pearlnest/screens/tenant/favorites_screen.dart";
import "package:pearlnest/screens/tenant/booking_screen.dart";
import "package:pearlnest/screens/tenant/booking_change_request_screen.dart";
import "package:pearlnest/screens/tenant/home_screen.dart";
import "package:pearlnest/screens/tenant/payment_screen.dart";
import "package:pearlnest/screens/tenant/property_details_screen.dart";
import "package:pearlnest/screens/tenant/refund_request_screen.dart";
import "package:pearlnest/services/profile_service.dart";
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

  bool _canCancelBooking(Booking booking) =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.confirmed;

  bool _canAskAboutBookingChange(Booking booking) {
    final bookingIsChatEligible =
        booking.status == BookingStatus.confirmed ||
            (booking.isViewingRequest &&
                booking.status == BookingStatus.pending);
    return bookingIsChatEligible &&
        (booking.hasSuccessfulPayment || (booking.amount ?? 0) <= 0);
  }

  bool _canRequestBookingChange(Booking booking) =>
      booking.status == BookingStatus.confirmed && !booking.isViewingRequest;

  bool _canRebook(Property property) =>
      property.availabilityStatus &&
      property.availableUnits > 0 &&
      property.status == PropertyStatus.approved;

  Future<void> _confirmCancellation(Booking booking) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          booking.hasSuccessfulPayment
              ? 'Your booking will be cancelled. Any completed payment is not refunded automatically; after cancellation, open booking history to submit a separate refund request under the applicable refund policy.'
              : 'Your booking will be cancelled. Any payment that has not completed will also be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      context.read<BookingBloc>().add(CancelBooking(bookingId: booking.id));
    }
  }

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

  Future<void> _openBookingChangeRequest(Booking booking) async {
    final changed = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BookingChangeRequestScreen(booking: booking),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final position = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: position, child: child),
          );
        },
      ),
    );
    if (changed == true && mounted) {
      context.read<BookingBloc>().add(FetchBookings());
    }
  }

  Future<void> _respondToBookingChange(
    Booking booking,
    BookingChangeRequest request,
    String decision,
  ) async {
    try {
      await BookingService.respondToBookingChange(
        requestId: request.id,
        decision: decision,
      );
      if (!mounted) return;
      context.read<BookingBloc>().add(FetchBookings());
      final message = decision == 'ACCEPT'
          ? 'The booking dates have been updated. Any remaining balance must be paid separately; a price reduction may be eligible for a refund request.'
          : decision == 'CANCEL'
              ? 'Change request cancelled.'
              : 'Change offer declined. Your existing booking is unchanged.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the change request: $error')),
      );
    }
  }

  Future<void> _payBookingBalance(Booking booking, int balance) async {
    final property = booking.property;
    if (property == null || balance <= 0) return;
    final amount = booking.successfulPaymentsTotal <= 0
        ? (booking.amount ?? balance.toDouble()).round()
        : balance;
    try {
      final payment = await PaymentService.createPayment(
        propertyId: booking.propertyId,
        bookingId: booking.id,
        amount: amount.toDouble(),
      );
      final redirectUrl = payment['redirectUrl']?.toString();
      final orderTrackingId = payment['orderTrackingId']?.toString();
      final merchantReference = payment['merchantReference']?.toString();
      if (payment['success'] != true ||
          redirectUrl == null ||
          redirectUrl.isEmpty ||
          orderTrackingId == null ||
          merchantReference == null) {
        throw BookingException(
          payment['message']?.toString() ??
              'Payment checkout could not be started.',
        );
      }
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            redirectUrl: redirectUrl,
            orderTrackingId: orderTrackingId,
            merchantReference: merchantReference,
            amount: amount.toDouble(),
            propertyTitle: booking.propertyTitle,
            user: widget.user,
            bookingStatus: 'APPROVED',
          ),
        ),
      );
      if (mounted) context.read<BookingBloc>().add(FetchBookings());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $error')),
      );
    }
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
                                  if (_canRequestBookingChange(booking))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _openBookingChangeRequest(booking),
                                        icon: const Icon(Icons.edit_calendar_outlined),
                                        label: const Text('Request date change'),
                                      ),
                                    ),
                                  if (booking.changeRequests.isNotEmpty)
                                    _buildBookingChangeStatus(
                                      booking,
                                      booking.changeRequests.first,
                                    ),
                                  if (booking.status == BookingStatus.confirmed &&
                                      balance > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _payBookingBalance(booking, balance.toInt()),
                                        icon: const Icon(Icons.payment_outlined),
                                        label: Text(
                                          'Pay remaining balance (${ProfileService().currencyConverter(price: balance.toInt())})',
                                        ),
                                      ),
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
                                  if (_canCancelBooking(booking))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (_canAskAboutBookingChange(booking) &&
                                              property.landlordId.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openLandlordChat(booking),
                                              icon: const Icon(
                                                Icons.edit_calendar_outlined,
                                              ),
                                              label: const Text(
                                                'Message landlord',
                                              ),
                                            ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _confirmCancellation(booking),
                                            icon: const Icon(
                                              Icons.cancel_outlined,
                                            ),
                                            label: const Text(
                                              'Cancel booking',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (successfulPayments.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.currency_exchange),
                                        label: Text(
                                          booking.landlordRejected
                                              ? 'Claim guaranteed refund'
                                              : booking.changeRequests.any(
                                                      (item) =>
                                                          item.status == 'ACCEPTED' &&
                                                          item.refundAmount > 0)
                                                  ? 'Request price-difference refund'
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
                                              bookingChangeRefund:
                                                  booking.changeRequests.any(
                                                (item) =>
                                                    item.status == 'ACCEPTED' &&
                                                    item.refundAmount > 0,
                                              ),
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
                                "Your booking was cancelled and a confirmation email has been sent. Any completed payment needs a separate refund request; cancellation does not automatically refund it.",
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

  Widget _buildBookingChangeStatus(
    Booking booking,
    BookingChangeRequest request,
  ) {
    final status = request.status;
    final quotedTotal = request.offeredQuote?['totalAmount'];
    final formattedTotal = quotedTotal is num
        ? 'UGX ${NumberFormat('#,##0').format(quotedTotal)}'
        : null;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (status) {
                'PENDING' => 'Change request sent',
                'OFFERED' => 'Landlord sent a change offer',
                'ACCEPTED' => 'Booking change accepted',
                'DECLINED' => 'Change request declined',
                'CANCELLED' => 'Change request cancelled',
                _ => 'Booking change update',
              },
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat.yMMMd().format(request.checkInDate)}'
              '${request.checkOutDate == null ? '' : ' – ${DateFormat.yMMMd().format(request.checkOutDate!)}'}'
              '${formattedTotal == null ? '' : '\nUpdated total: $formattedTotal'}',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
            if (status == 'OFFERED') ...[
              const SizedBox(height: 10),
              const Text(
                'Your current booking is unchanged until you accept. A higher total will leave a balance to pay; a lower total may require a separate refund request.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () =>
                        _respondToBookingChange(booking, request, 'ACCEPT'),
                    child: const Text('Accept offer'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _respondToBookingChange(booking, request, 'DECLINE'),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ] else if (status == 'PENDING')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      _respondToBookingChange(booking, request, 'CANCEL'),
                  child: const Text('Cancel request'),
                ),
              ),
          ],
        ),
      ),
    );
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
