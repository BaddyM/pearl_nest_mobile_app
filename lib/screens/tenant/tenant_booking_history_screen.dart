import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class TenantBookingHistoryScreen extends StatefulWidget {
  final User user;

  const TenantBookingHistoryScreen({
    super.key,
    required this.user,
  });

  @override
  State<TenantBookingHistoryScreen> createState() => _TenantBookingHistoryScreenState();
}

class _TenantBookingHistoryScreenState extends State<TenantBookingHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<Booking> _allBookings = [];
  BookingStatus _selectedStatus = BookingStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch tenant bookings
    if (_allBookings.isEmpty) {
      context.read<BookingBloc>().add(const FetchBookings());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    });
  }

  List<Booking> _getFilteredBookings() {
    return _allBookings.where((booking) {
      final matchesStatus = booking.status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty || booking.propertyTitle.toLowerCase().contains(_searchQuery.toLowerCase()) || booking.propertyTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
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
      case BookingStatus.expired:
        return Colors.purple;
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
      case BookingStatus.expired:
        return 'Expired';
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

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsModal(booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryblue),
            ),
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BookingBloc>().add(const FetchBookings());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      foregroundColor: AppTheme.whiteColor,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Center(
            child: Text(
              'No bookings found.',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
              ),
            ),
          ),
        );
      },
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
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View your booking history',
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
                  onPressed: () {
                    context.read<BookingBloc>().add(const FetchBookings());
                  },
                  icon: Icon(
                    Icons.refresh,
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
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search bookings...',
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryblue,
        labelColor: AppTheme.primaryblue,
        unselectedLabelColor: AppTheme.getSecondaryTextColor(context),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        tabs: [
          Tab(text: 'Pending'),
          Tab(text: 'Confirmed'),
          Tab(text: 'Cancelled'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    final filteredBookings = _getFilteredBookings();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookingBloc>().add(const FetchBookings());
      },
      color: AppTheme.primaryblue,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.pending_actions;
    switch (_selectedStatus) {
      case BookingStatus.pending:
        message = 'No pending bookings';
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
      case BookingStatus.expired:
        message = 'No expired bookings';
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
              color: AppTheme.primaryblue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.primaryblue,
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
            _searchQuery.isNotEmpty ? 'Try adjusting your search terms' : 'Your bookings will appear here',
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
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBookingDetails(booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.propertyTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Property: ${booking.propertyTitle}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${booking.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getBookingTypeText(booking.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryblue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(booking.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(booking.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(booking.status),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Booking Date: ${_formatDate(booking.requestedDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
                if (booking.type == BookingType.viewing) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Time: ${_formatTime(booking.requestedDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Created ${_getTimeAgo(booking.createdAt)}',
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
        ),
      ),
    );
  }

  Widget _buildBookingDetailsModal(Booking booking) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Property', booking.propertyTitle),
                  _buildDetailRow('Booking ID', booking.id),
                  _buildDetailRow('Property', booking.propertyTitle),
                  _buildDetailRow('Type', _getBookingTypeText(booking.type)),
                  _buildDetailRow('Status', _getStatusText(booking.status)),
                  _buildDetailRow('Booking Date', _formatDate(booking.requestedDate)),
                  if (booking.type == BookingType.viewing) _buildDetailRow('Time', _formatTime(booking.requestedDate)),
                  _buildDetailRow('Created', _formatDate(booking.createdAt)),
                  if (booking.message != null && booking.message!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Message:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        booking.message!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
