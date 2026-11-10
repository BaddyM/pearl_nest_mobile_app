import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/chat_conversation.dart';
import 'package:pearlnest/screens/chat/individual_chat_screen.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/loading_widget.dart';
import 'package:pearlnest/widgets/login_required_widget.dart';
import 'package:pearlnest/utils/image_helper.dart';

class NewChatList extends StatefulWidget {
  const NewChatList({
    super.key,
    required this.user,
    this.showBackButton = true,
  });
  final User user;
  final bool showBackButton;

  @override
  State<NewChatList> createState() => _NewChatListState();
}

class _NewChatListState extends State<NewChatList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.id != "") {
      context.read<NewChatBloc>().socket.connect(widget.user.id);
      _fetchChatList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchChatList() {
    context.read<NewChatBloc>().add(
          FetchNewChatList(
            loadAdminsIfEmpty: widget.user.userType != UserType.landlord,
          ),
        );
  }

  Future<void> _refreshChatList() async {
    final bloc = context.read<NewChatBloc>();
    bloc.add(
      FetchNewChatList(
        loadAdminsIfEmpty: widget.user.userType != UserType.landlord,
      ),
    );
    await bloc.stream.firstWhere(
      (state) =>
          state is NewChatListLoadedState ||
          state is NewChatListInitState ||
          state is NewChatListErrorState,
    );
  }

  String convertUserType(UserType userType) {
    switch (userType) {
      case UserType.landlord:
        return "Landlord";
      case UserType.tenant:
        return "Tenant";
      case UserType.admin:
        return "Admin";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton ? const BackButton() : null,
        title: const Text("Messages"),
        centerTitle: false,
        actions: [
          if (widget.user.id != "")
            IconButton(
              tooltip: 'Refresh conversations',
              onPressed: _fetchChatList,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.user.id != ""
          ? BlocConsumer<NewChatBloc, NewChatState>(
              builder: (context, state) {
                if (state is NewChatListLoadingState) {
                  return Column(
                    children: [
                      _buildConversationTools(const []),
                      Expanded(
                        child: LoadingWidget(
                          height: MediaQuery.of(context).size.height * 0.8,
                        ),
                      ),
                    ],
                  );
                } else if (state is NewChatListLoadedState) {
                  return _buildConversationList(
                    state.data,
                    isAdminList: false,
                  );
                } else if (state is NewChatListInitState) {
                  return _buildConversationList(
                    state.data,
                    isAdminList: true,
                  );
                } else {
                  return Column(
                    children: [
                      _buildConversationTools(const []),
                      Expanded(child: _buildEmptyConversations()),
                    ],
                  );
                }
              },
              listener: (context, state) {
                if (state is NewChatListErrorState) {
                  CustomSnackBar.showError(context, state.error);
                } else if (state is NewChatListLoadedState &&
                    state.refreshError != null) {
                  CustomSnackBar.showError(
                    context,
                    state.refreshError!,
                  );
                } else if (state is NewChatListInitState &&
                    state.refreshError != null) {
                  CustomSnackBar.showError(
                    context,
                    state.refreshError!,
                  );
                }
              },
            )
          : Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: double.maxFinite,
              alignment: Alignment.center,
              child: LoginRequiredWidget(),
            ),
    );
  }

  Widget _buildConversationList(
    List<Map<String, dynamic>> data, {
    required bool isAdminList,
  }) {
    final visibleItems = _filteredItems(data, isAdminList: isAdminList);
    final unreadCount =
        isAdminList ? 0 : data.where(_isUnreadConversation).length;

    return Column(
      children: [
        _buildConversationTools(
          data,
          unreadCount: unreadCount,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshChatList,
            color: AppTheme.primaryblue,
            child: visibleItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.62,
                        child: data.isEmpty
                            ? _buildEmptyConversations()
                            : _buildNoMatchingConversations(),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      if (isAdminList) {
                        return _buildChatListCard(
                          item["name"]?.toString() ?? "Support",
                          widget.user.id,
                          item["role"]?.toString() ?? "",
                          item["id"]?.toString() ?? "",
                          imageUrl: _profilePhotoUrl(item),
                          adminContact: item["contact"]?.toString() ?? "",
                          isOnline: item["isOnline"] == true,
                          preview: 'Chat with our support team',
                        );
                      }

                      final isCurrentUserSender =
                          item["fromUserId"]?.toString() == widget.user.id;
                      final peer = isCurrentUserSender
                          ? item["toUser"]
                          : item["fromUser"];
                      final peerData = peer is Map
                          ? Map<String, dynamic>.from(peer)
                          : <String, dynamic>{};
                      final property = item["property"] is Map
                          ? Map<String, dynamic>.from(item["property"])
                          : <String, dynamic>{};
                      final id = isCurrentUserSender
                          ? item["toUserId"]?.toString() ?? ""
                          : item["fromUserId"]?.toString() ?? "";
                      final unread =
                          int.tryParse(item["unreadCount"]?.toString() ?? '') ??
                              (_isUnreadConversation(item) ? 1 : 0);

                      return _buildChatListCard(
                        peerData["name"]?.toString() ?? "User",
                        widget.user.id,
                        peerData["role"]?.toString() ?? "",
                        id,
                        adminContact: peerData["contact"]?.toString() ??
                            peerData["phone"]?.toString() ??
                            "",
                        imageUrl: _profilePhotoUrl(peerData),
                        propertyId: item["propertyId"]?.toString(),
                        propertyTitle: property["propertyName"]?.toString(),
                        propertyAddress: property["fullAddress"]?.toString(),
                        isOnline: peerData["isOnline"] == true,
                        unread: unread > 0,
                        unreadCount: unread,
                        preview:
                            _conversationPreview(item, isCurrentUserSender),
                        timestamp: _conversationTimestamp(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTools(
    List<Map<String, dynamic>> items, {
    int unreadCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your conversations',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${items.length} ${items.length == 1 ? 'conversation' : 'conversations'}'
                      '${unreadCount > 0 ? ' · $unreadCount unread' : ''}',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  color: AppTheme.primaryblue,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search people or properties',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppTheme.getCardColor(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryblue.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChip(
                label: 'All',
                selected: !_showUnreadOnly,
                onTap: () => setState(() => _showUnreadOnly = false),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: unreadCount > 0 ? 'Unread $unreadCount' : 'Unread',
                selected: _showUnreadOnly,
                onTap: () => setState(() => _showUnreadOnly = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color:
            selected ? Colors.white : AppTheme.getSecondaryTextColor(context),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      selectedColor: AppTheme.primaryblue,
      backgroundColor: AppTheme.getCardColor(context),
      side: BorderSide(
        color: selected
            ? AppTheme.primaryblue
            : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  List<Map<String, dynamic>> _filteredItems(
    List<Map<String, dynamic>> items, {
    required bool isAdminList,
  }) {
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      if (_showUnreadOnly && (isAdminList || !_isUnreadConversation(item))) {
        return false;
      }
      if (query.isEmpty) return true;

      final isCurrentUserSender =
          item["fromUserId"]?.toString() == widget.user.id;
      final peer = isAdminList
          ? item
          : isCurrentUserSender
              ? item["toUser"]
              : item["fromUser"];
      final peerData =
          peer is Map ? Map<String, dynamic>.from(peer) : <String, dynamic>{};
      final property = item["property"] is Map
          ? Map<String, dynamic>.from(item["property"])
          : <String, dynamic>{};
      final searchable = [
        peerData["name"],
        peerData["role"],
        property["propertyName"],
        property["fullAddress"],
        item["lastMessage"],
        item["message"],
      ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  bool _isUnreadConversation(Map<String, dynamic> item) {
    final unreadCount = int.tryParse(item["unreadCount"]?.toString() ?? '');
    if (unreadCount != null) return unreadCount > 0;
    return item["fromUserId"]?.toString() != widget.user.id &&
        item["isRead"] != true;
  }

  String _conversationPreview(
    Map<String, dynamic> item,
    bool isCurrentUserSender,
  ) {
    final message = (item["lastMessage"] ?? item["message"])?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return isCurrentUserSender ? 'You: $message' : message;
    }

    final property = item["property"] is Map
        ? Map<String, dynamic>.from(item["property"])
        : <String, dynamic>{};
    final title = property["propertyName"]?.toString().trim();
    return title != null && title.isNotEmpty
        ? 'Conversation about $title'
        : 'Tap to continue your conversation';
  }

  String? _conversationTimestamp(Map<String, dynamic> item) {
    final rawValue =
        item["lastMessageTime"] ?? item["createdAt"] ?? item["updatedAt"];
    if (rawValue == null) return null;
    final timestamp = DateTime.tryParse(rawValue.toString())?.toLocal();
    if (timestamp == null) return null;

    final now = DateTime.now();
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return DateFormat('h:mm a').format(timestamp);
    }
    if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    }
    return DateFormat('d MMM').format(timestamp);
  }

  Widget _buildNoMatchingConversations() {
    final message = _showUnreadOnly
        ? 'You’re all caught up.'
        : 'Try another name or property.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showUnreadOnly
                  ? Icons.mark_chat_read_outlined
                  : Icons.search_off_rounded,
              size: 44,
              color: AppTheme.primaryblue.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _showUnreadOnly ? 'No unread messages' : 'No matches found',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 44,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages about your properties will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  String? _profilePhotoUrl(Map<String, dynamic> user) {
    final value = user['profilePicture'] ??
        user['profileImage'] ??
        user['profilePhoto'] ??
        user['avatar'];
    if (value is! String ||
        value.trim().isEmpty ||
        value.trim().toLowerCase() == 'undefined' ||
        value.trim().toLowerCase() == 'null') {
      return null;
    }
    return ImageHelper.getFullImageUrl(value.trim());
  }

  Widget _buildChatListCard(
    String userName,
    String currentUserId,
    String role,
    String toUserId, {
    String? propertyId,
    String? propertyTitle,
    String? propertyAddress,
    String? imageUrl,
    String adminContact = '',
    bool isOnline = false,
    bool unread = false,
    int unreadCount = 0,
    String? preview,
    String? timestamp,
  }) {
    Future<void> openConversation() async {
      final conversation = ChatConversation(
        id: '$currentUserId-$toUserId-${propertyId ?? 'general'}',
        landlordId: toUserId,
        landlordName: userName,
        landlordProfilePic: imageUrl ?? '',
        lastMessage: preview ?? '',
        lastMessageTime: DateTime.now(),
        unreadCount: unreadCount,
        isOnline: isOnline,
        propertyTitle: propertyTitle?.trim().isNotEmpty == true
            ? propertyTitle!
            : 'General conversation',
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IndividualChatScreen(
            conversation: conversation,
            currentUser: widget.user,
            isOnline: isOnline,
            adminContact: adminContact,
            propertyId: propertyId,
            propertyAddress: propertyAddress,
          ),
        ),
      );
    }

    return Dismissible(
      key: ValueKey('$toUserId-${propertyId ?? propertyTitle ?? 'general'}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.primaryblue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'Open',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await openConversation();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread
                ? AppTheme.primaryblue.withValues(alpha: 0.24)
                : AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryblue.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openConversation,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.primaryblue
                                      .withValues(alpha: 0.1),
                                  backgroundImage: imageProvider,
                                ),
                                placeholder: (context, url) =>
                                    _buildDefaultAvatar(userName),
                                errorWidget: (context, url, error) =>
                                    _buildDefaultAvatar(userName),
                              )
                            : _buildDefaultAvatar(userName),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.getCardColor(context),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  color: AppTheme.getTextColor(context),
                                  fontSize: 15,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timestamp != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                timestamp,
                                style: TextStyle(
                                  color: unread
                                      ? AppTheme.primaryblue
                                      : AppTheme.getSecondaryTextColor(context),
                                  fontSize: 11,
                                  fontWeight: unread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (propertyTitle != null &&
                                propertyTitle.trim().isNotEmpty)
                              Expanded(
                                child: Text(
                                  propertyTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        AppTheme.getSecondaryTextColor(context),
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else if (role.trim().isNotEmpty)
                              Expanded(
                                child: Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.primaryblue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (unread && unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryblue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          preview?.trim().isNotEmpty == true
                              ? preview!
                              : propertyAddress?.trim().isNotEmpty == true
                                  ? propertyAddress!
                                  : 'Tap to open conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread
                                ? AppTheme.getTextColor(context)
                                : AppTheme.getSecondaryTextColor(context),
                            fontSize: 12,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (propertyTitle != null &&
                            propertyTitle.trim().isNotEmpty &&
                            role.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: AppTheme.primaryblue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryblue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
