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
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton ? BackButton() : null,
        title: Text("Chat"),
        centerTitle: false,
        actions: [
          if (widget.user.id != "")
            GestureDetector(
              onTap: _fetchChatList,
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 30,
              ),
            ),
          SizedBox(width: 10),
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
                        child: state.data.isEmpty
                            ? _buildEmptyConversations()
                            : ListView.builder(
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
                                      ? Map<String, dynamic>.from(item["property"])
                                      : <String, dynamic>{};
                                  final id = isCurrentUserSender
                                      ? item["toUserId"]?.toString() ?? ""
                                      : item["fromUserId"]?.toString() ?? "";
                                  final unreadCount =
                                      int.tryParse(item["unreadCount"]?.toString() ?? '');
                                  final isUnread = unreadCount != null
                                      ? unreadCount > 0
                                      : !isCurrentUserSender && item["isRead"] != true;
                                  return _buildChatListCard(
                                    name,
                                    widget.user.id,
                                    role,
                                    id,
                                    imageUrl: profilePhoto,
                                    propertyId: item["propertyId"]?.toString(),
                                    propertyTitle: property["propertyName"]?.toString(),
                                    propertyAddress: property["fullAddress"]?.toString(),
                                    isOnline: isOnline,
                                    unread: isUnread,
                                  );
                                },
                              ),
                      );
                    } else if (state is NewChatListInitState) {
                      return Expanded(
                        child: state.data.isEmpty
                            ? _buildEmptyConversations()
                            : ListView.builder(
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
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                  listener: (context, state) {
                    if (state is NewChatListErrorState) {
                      CustomSnackBar.showError(context, state.error);
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.of(context).push(
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
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryblue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppTheme.primaryblue.withValues(alpha: 0.1),
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) =>
                              _buildDefaultAvatar(userName),
                          errorWidget: (context, url, error) =>
                              _buildDefaultAvatar(userName),
                        )
                      : _buildDefaultAvatar(userName),
                ),
                SizedBox(width: 16),

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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Online status indicator
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryblue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (propertyTitle != null && propertyTitle.trim().isNotEmpty) ...[
                        SizedBox(height: 4),
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
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.check_circle : Icons.schedule,
                            size: 14,
                            color: isOnline ? Colors.green : Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isOnline ? 'Available' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat arrow
                unread == true
                    ? Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      )
                    : SizedBox(),
              ],
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
