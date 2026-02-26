import 'package:add_comma/add_comma.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class LandlordBookingRequestsScreen extends StatefulWidget {
  final User user;

  const LandlordBookingRequestsScreen({
    super.key,
    required this.user,
  });

  @override
  State<LandlordBookingRequestsScreen> createState() => _LandlordBookingRequestsScreenState();
}

class _LandlordBookingRequestsScreenState extends State<LandlordBookingRequestsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isLoading = false;
  List<Booking> _allBookings = [];
  BookingStatus _selectedStatus = BookingStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Fetch bookings in didChangeDependencies to ensure context is available
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch once
    if (_allBookings.isEmpty) {
      context.read<BookingBloc>().add(const FetchLandlordBookings());
    }
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = BookingStatus.pending;
          break;
        case 1:
          _selectedStatus = BookingStatus.confirmed;
          break;
        case 2:
          _selectedStatus = BookingStatus.cancelled;
          break;
        case 3:
          _selectedStatus = BookingStatus.completed;
          break;
      }
      // Filter bookings will be handled in build method
    });
  }

  List<Booking> _getFilteredBookings() {
    return _allBookings.where((booking) {
      final matchesStatus = booking.status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty || booking.tenantName.toLowerCase().contains(_searchQuery.toLowerCase()) || booking.propertyTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  String _getBookingTypeText(BookingType type) {
    switch (type) {
      case BookingType.viewing:
        return 'Property Viewing';
      case BookingType.rental:
        return 'Rental';
      case BookingType.monthly:
        return 'Monthly Rental';
      case BookingType.daily:
        return 'Daily Rental';
    }
  }

  void _handleBookingAction(Booking booking, BookingStatus newStatus) {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final actionText = newStatus == BookingStatus.confirmed ? 'accepted' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking request $actionText successfully!',
            style: TextStyle(color: AppTheme.lightGreyColor),
          ),
          backgroundColor: newStatus == BookingStatus.confirmed ? AppTheme.primaryblue : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(milliseconds: 500),
          margin: EdgeInsets.all(16),
        ),
      );

      // Filtering will be handled automatically in build method
    });
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsModal(booking),
    );
  }

  void _contactTenant(String tenantId) {
    final bookingBloc = context.read<BookingBloc>();
    final state = bookingBloc.state;
    String tenantPhone = 'No phone';
    if (state is BookingLoaded) {
      final booking = state.bookings.firstWhere(
        (b) => b.tenantId == tenantId,
        orElse: () => Booking.empty(),
      );
      tenantPhone = booking.tenantPhone;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calling $tenantPhone...',
          style: TextStyle(color: AppTheme.lightGreyColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 500),
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
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
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppTheme.blackColor,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Booking Requests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your property bookings',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryblue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSearchBar(),
          SizedBox(height: 16),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            // Filtering will be handled automatically in build method
          });
        },
        style: TextStyle(
          color: AppTheme.getTextColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search bookings, tenants, properties...',
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Icon(Icons.search, color: AppTheme.getSecondaryTextColor(context)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.getSecondaryTextColor(context)),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      // Filtering will be handled automatically in build method
                    });
                  },
                )
              : Icon(Icons.tune, color: AppTheme.primaryblue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final bookingsToCount = _allBookings;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryblue,
        unselectedLabelColor: AppTheme.getSecondaryTextColor(context),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        indicator: BoxDecoration(
          color: AppTheme.primaryblue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: EdgeInsets.symmetric(horizontal: -8, vertical: 8),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Pending (${bookingsToCount.where((b) => b.status == BookingStatus.pending).length})'),
          Tab(text: 'Confirmed (${bookingsToCount.where((b) => b.status == BookingStatus.confirmed).length})'),
          Tab(text: 'Cancelled (${bookingsToCount.where((b) => b.status == BookingStatus.cancelled).length})'),
          Tab(text: 'Completed (${bookingsToCount.where((b) => b.status == BookingStatus.completed).length})'),
        ],
      ),
    );
  }

  // All widget methods below are inside the class
  Widget _buildBookingsList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryblue),
      );
    }
    final filteredBookings = _getFilteredBookings();
    if (filteredBookings.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: _buildBookingCard(booking),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.pending_actions;
    switch (_selectedStatus) {
      case BookingStatus.pending:
        message = 'No pending booking requests';
        icon = Icons.pending_actions;
        break;
      case BookingStatus.confirmed:
        message = 'No confirmed bookings';
        icon = Icons.check_circle_outline;
        break;
      case BookingStatus.cancelled:
        message = 'No cancelled bookings';
        icon = Icons.cancel_outlined;
        break;
      case BookingStatus.completed:
        message = 'No completed bookings';
        icon = Icons.task_alt;
        break;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.lightGreyColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Try adjusting your search terms' : 'New requests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final tenantName = booking.tenantName;
    final propertyTitle = booking.propertyTitle;
    final statusColor = _getStatusColor(booking.status);
    final formattedAmount = booking.amount != null ? NumberFormat('#,##0').format(booking.amount) : '0';

    return GestureDetector(
        onTap: () => _showBookingDetails(booking),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryblue.withValues(alpha: 0.1),
                      child: Text(
                        tenantName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryblue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenantName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _getBookingTypeText(booking.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(booking.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home, size: 16, color: AppTheme.getSecondaryTextColor(context)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              propertyTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: AppTheme.getSecondaryTextColor(context)),
                                SizedBox(width: 6),
                                Text(
                                  'Check-in: ${_formatDate(booking.startDate ?? booking.requestedDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (booking.startDate != null && booking.endDate != null)
                            Text(
                              '${(booking.endDate!.difference(booking.startDate!).inDays)} days',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                        ],
                      ),
                      if (booking.endDate != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event, size: 14, color: AppTheme.getSecondaryTextColor(context)),
                            SizedBox(width: 6),
                            Text(
                              'Check-out: ${_formatDate(booking.endDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                'UGX$formattedAmount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryblue,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '• ${_getTimeAgo(booking.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getSecondaryTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // if (booking.status == BookingStatus.pending) ...[
                    //   SizedBox(width: 8),
                    //   Row(
                    //     children: [
                    //       GestureDetector(
                    //         onTap: () => _handleBookingAction(booking, BookingStatus.cancelled),
                    //         child: Container(
                    //           padding: EdgeInsets.all(8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.red.withOpacity(0.1),
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: Icon(
                    //             Icons.close,
                    //             color: Colors.red,
                    //             size: 20,
                    //           ),
                    //         ),
                    //       ),
                    //       SizedBox(width: 8),
                    //       GestureDetector(
                    //         onTap: () => _handleBookingAction(booking, BookingStatus.confirmed),
                    //         child: Container(
                    //           padding: EdgeInsets.all(8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.green.withOpacity(0.1),
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: Icon(
                    //             Icons.check,
                    //             color: Colors.green,
                    //             size: 20,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ] else ...[
                    //   GestureDetector(
                    //     onTap: () => _contactTenant(booking.tenantId),
                    //     child: Container(
                    //       padding: EdgeInsets.all(8),
                    //       decoration: BoxDecoration(
                    //         color: AppTheme.primaryblue.withOpacity(0.1),
                    //         shape: BoxShape.circle,
                    //       ),
                    //       child: Icon(
                    //         Icons.phone,
                    //         color: AppTheme.primaryblue,
                    //         size: 20,
                    //       ),
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildBookingDetailsModal(Booking booking) {
    final tenantName = booking.tenantName;
    final tenantEmail = booking.tenantEmail;
    final tenantPhone = booking.tenantPhone;
    final propertyTitle = booking.propertyTitle;
    final statusColor = _getStatusColor(booking.status);
    final putCommas = addCommas();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(booking.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildDetailSection(
                    'Tenant Information',
                    Icons.person,
                    [
                      _buildDetailRow('Name', tenantName),
                      _buildDetailRow('Email', tenantEmail),
                      _buildDetailRow('Phone', tenantPhone),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildDetailSection(
                    'Property Information',
                    Icons.home,
                    [
                      _buildDetailRow('Property', propertyTitle),
                      _buildDetailRow('Booking Type', _getBookingTypeText(booking.type)),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildDetailSection(
                    'Booking Information',
                    Icons.calendar_today,
                    [
                      _buildDetailRow('Requested Date', _formatDate(booking.requestedDate)),
                      if (booking.startDate != null) _buildDetailRow('Check-in Date', _formatDate(booking.startDate!)),
                      if (booking.endDate != null) _buildDetailRow('Check-out Date', _formatDate(booking.endDate!)),
                      if (booking.startDate != null && booking.endDate != null) _buildDetailRow('Duration', '${booking.endDate!.difference(booking.startDate!).inDays} days'),
                      _buildDetailRow(
                        'Amount',
                        '${ProfileService().currencyConverter(price: (booking.amount ?? 0).toInt())}',
                      ),
                      _buildDetailRow('Created', '${_formatDate(booking.createdAt)} at ${_formatTime(booking.createdAt)}'),
                    ],
                  ),
                  if (booking.message != null && booking.message!.isNotEmpty) ...[
                    SizedBox(height: 24),
                    _buildDetailSection(
                      'Message from Tenant',
                      Icons.message,
                      [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getCardColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.message!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.getTextColor(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // SizedBox(height: 32),
                  // if (booking.status == BookingStatus.pending) ...[
                  //   Row(
                  //     children: [
                  //       Expanded(
                  //         child: ElevatedButton(
                  //           onPressed: () {
                  //             Navigator.pop(context);
                  //             _handleBookingAction(booking, BookingStatus.cancelled);
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: Colors.red,
                  //             foregroundColor: AppTheme.whiteColor,
                  //             padding: EdgeInsets.symmetric(vertical: 16),
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(12),
                  //             ),
                  //             elevation: 0,
                  //           ),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(Icons.close, size: 20),
                  //               SizedBox(width: 8),
                  //               Text(
                  //                 'Reject',
                  //                 style: TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight.w600,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //       SizedBox(width: 16),
                  //       Expanded(
                  //         child: ElevatedButton(
                  //           onPressed: () {
                  //             Navigator.pop(context);
                  //             _handleBookingAction(booking, BookingStatus.confirmed);
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: AppTheme.primaryblue,
                  //             foregroundColor: AppTheme.whiteColor,
                  //             padding: EdgeInsets.symmetric(vertical: 16),
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(12),
                  //             ),
                  //             elevation: 0,
                  //           ),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(Icons.check, size: 20),
                  //               SizedBox(width: 8),
                  //               Text(
                  //                 'Accept',
                  //                 style: TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight.w600,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  //   SizedBox(height: 12),
                  // ],
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => _contactTenant(booking.tenantId),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppTheme.getCardColor(context).withValues(alpha: 1.5),
                  //       foregroundColor: AppTheme.getTextColor(context),
                  //       padding: EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(Icons.phone, size: 20),
                  //         SizedBox(width: 8),
                  //         Text(
                  //           'Contact Tenant',
                  //           style: TextStyle(
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryblue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withValues(alpha: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Builder to ensure context is under MultiBlocProvider
    return Builder(
      builder: (context) {
        return BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return Scaffold(
                backgroundColor: AppTheme.getBackgroundColor(context),
                body: Center(child: CircularProgressIndicator(color: AppTheme.primaryblue)),
              );
            } else if (state is BookingLoaded) {
              _allBookings = state.bookings;
              return Scaffold(
                backgroundColor: AppTheme.getBackgroundColor(context),
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildBookingsList()),
                    ],
                  ),
                ),
              );
            } else if (state is BookingError) {
              return Scaffold(
                backgroundColor: AppTheme.getBackgroundColor(context),
                body: Center(child: Text(state.message, style: TextStyle(color: Colors.red))),
              );
            }
            return Scaffold(
              backgroundColor: AppTheme.getBackgroundColor(context),
              body: Center(child: Text('No bookings found.')),
            );
          },
        );
      },
    );
  }
}

class LandlordProfileScreen extends StatelessWidget {
  final User user;
  final Landlord landlord;

  const LandlordProfileScreen({
    super.key,
    required this.user,
    required this.landlord,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blackColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryblue, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.lightGreyColor,
                      child: user.profileImage != null && user.profileImage!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                ImageHelper.getFullImageUrl(user.profileImage!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, color: AppTheme.primaryblue, size: 40);
                                },
                              ),
                            )
                          : Icon(Icons.person, color: AppTheme.primaryblue, size: 40),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blackColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          landlord.businessName,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              landlord.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.blackColor,
                              ),
                            ),
                            Text(
                              ' • Landlord',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Edit profile coming soon!',
                            style: TextStyle(color: AppTheme.lightGreyColor),
                          ),
                          duration: Duration(milliseconds: 500),
                          backgroundColor: AppTheme.primaryblue,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit, color: AppTheme.primaryblue),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildProfileOption(
              context,
              'Personal Information',
              Icons.person_outline,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Business Details',
              Icons.business_outlined,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Payment Settings',
              Icons.payment_outlined,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Notifications',
              Icons.notifications_outlined,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Privacy & Security',
              Icons.security_outlined,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Help & Support',
              Icons.help_outline,
              () => _showComingSoon(context),
            ),
            _buildProfileOption(
              context,
              'Terms & Conditions',
              Icons.description_outlined,
              () => _showComingSoon(context),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryblue, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.blackColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.greyColor,
          size: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.whiteColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This feature is coming soon!',
          style: TextStyle(color: AppTheme.lightGreyColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(milliseconds: 500),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged out successfully',
                      style: TextStyle(color: AppTheme.lightGreyColor),
                    ),
                    backgroundColor: AppTheme.primaryblue,
                    duration: Duration(milliseconds: 500),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: AppTheme.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
