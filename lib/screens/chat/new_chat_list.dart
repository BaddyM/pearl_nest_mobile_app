import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/new_chat_conversation.dart';
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
  @override
  void initState() {
    super.initState();
    if (widget.user.id != "") {
      context.read<NewChatBloc>().socket.connect(widget.user.id);
      _fetchChatList();
    }
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
          ? Column(
              children: [
                BlocConsumer<NewChatBloc, NewChatState>(
                  builder: (context, state) {
                    if (state is NewChatListLoadingState) {
                      return LoadingWidget(
                        height: MediaQuery.of(context).size.height * 0.8,
                      );
                    } else if (state is NewChatListLoadedState) {
                      return Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshChatList,
                          color: AppTheme.primaryblue,
                          child: state.data.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7,
                                      child: _buildEmptyConversations(),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.data.length,
                                  itemBuilder: (context, index) {
                                    final item = state.data[index];
                                    final isCurrentUserSender =
                                        item["fromUserId"] == widget.user.id;
                                    final peer = isCurrentUserSender
                                        ? item["toUser"]
                                        : item["fromUser"];
                                    final peerData = peer is Map
                                        ? Map<String, dynamic>.from(peer)
                                        : <String, dynamic>{};
                                    final name =
                                        peerData["name"]?.toString() ?? "User";
                                    final role =
                                        peerData["role"]?.toString() ?? "";
                                    final isOnline =
                                        peerData["isOnline"] == true;
                                    final profilePhoto =
                                        _profilePhotoUrl(peerData);
                                    final property = item["property"] is Map
                                        ? Map<String, dynamic>.from(
                                            item["property"])
                                        : <String, dynamic>{};
                                    final id = isCurrentUserSender
                                        ? item["toUserId"]?.toString() ?? ""
                                        : item["fromUserId"]?.toString() ?? "";
                                    final unreadCount = int.tryParse(
                                        item["unreadCount"]?.toString() ?? '');
                                    final isUnread = unreadCount != null
                                        ? unreadCount > 0
                                        : !isCurrentUserSender &&
                                            item["isRead"] != true;
                                    return _buildChatListCard(
                                      name,
                                      widget.user.id,
                                      role,
                                      id,
                                      imageUrl: profilePhoto,
                                      propertyId:
                                          item["propertyId"]?.toString(),
                                      propertyTitle:
                                          property["propertyName"]?.toString(),
                                      propertyAddress:
                                          property["fullAddress"]?.toString(),
                                      isOnline: isOnline,
                                      unread: isUnread,
                                    );
                                  },
                                ),
                        ),
                      );
                    } else if (state is NewChatListInitState) {
                      return Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshChatList,
                          color: AppTheme.primaryblue,
                          child: state.data.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7,
                                      child: _buildEmptyConversations(),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.data.length,
                                  itemBuilder: (context, index) {
                                    final admin = state.data[index];
                                    return _buildChatListCard(
                                      admin["name"]?.toString() ?? "Support",
                                      widget.user.id,
                                      admin["role"]?.toString() ?? "",
                                      admin["id"]?.toString() ?? "",
                                      imageUrl: _profilePhotoUrl(
                                        Map<String, dynamic>.from(admin),
                                      ),
                                      propertyTitle: null,
                                      propertyAddress: null,
                                      isOnline: admin["isOnline"] == true,
                                      unread: false,
                                    );
                                  },
                                ),
                        ),
                      );
                    } else {
                      return SizedBox();
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
                ),
              ],
            )
          : Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: double.maxFinite,
              alignment: Alignment.center,
              child: LoginRequiredWidget(),
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
    bool isOnline = false,
    bool unread = false,
  }) {
    Future<void> openConversation() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewChatConversation(
            fromUserId: currentUserId,
            toUserId: toUserId,
            userName: userName,
            userImageUrl: imageUrl,
            propertyId: propertyId,
            propertyTitle: propertyTitle,
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
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 14),

                  // Admin Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                userName,
                                style: TextStyle(
                                  color: AppTheme.getTextColor(context),
                                  fontSize: 16,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Online status indicator
                          ],
                        ),
                        if (role.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: AppTheme.primaryblue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (propertyTitle != null &&
                            propertyTitle.trim().isNotEmpty) ...[
                          SizedBox(height: role.trim().isNotEmpty ? 3 : 6),
                          Text(
                            propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.getSecondaryTextColor(context),
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
