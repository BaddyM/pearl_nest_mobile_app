import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/new_chat_conversation.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/loading_widget.dart';
import 'package:pearlnest/widgets/login_required_widget.dart';

class NewChatList extends StatefulWidget {
  const NewChatList({super.key, required this.user});
  final User user;

  @override
  State<NewChatList> createState() => _NewChatListState();
}

class _NewChatListState extends State<NewChatList> {
  @override
  void initState() {
    super.initState();
    if (widget.user.id != "") {
      _fetchChatList();
    }
  }

  void _fetchChatList() {
    context.read<NewChatBloc>().add(FetchNewChatList());
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
        leading: BackButton(),
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
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.875,
                        padding: EdgeInsets.all(16),
                        child: ListView.builder(
                            physics: ScrollPhysics(),
                            itemCount: state.data.length,
                            itemBuilder: (context, index) {
                              String name = state.data[index]["fromUser"]["name"];
                              String role = state.data[index]["fromUser"]["role"];
                              bool isOnline = state.data[index]["fromUser"]["isOnline"];
                              String id = state.data[index]["fromUserId"];
                              bool isRead = state.data[index]["isRead"];
                              return _buildChatListCard(
                                name,
                                widget.user.id,
                                role,
                                id,
                                isOnline: isOnline,
                                unread: isRead,
                              );
                            }),
                      );
                    } else if (state is NewChatListInitState) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.875,
                        padding: EdgeInsets.all(16),
                        child: ListView.builder(
                            physics: ScrollPhysics(),
                            itemCount: state.data.length,
                            itemBuilder: (context, index) {
                              String name = state.data[index]["name"];
                              String role = state.data[index]["role"];
                              bool isOnline = state.data[index]["isOnline"];
                              String id = state.data[index]["id"];
                              return _buildChatListCard(
                                name,
                                widget.user.id,
                                role,
                                id,
                                isOnline: isOnline,
                                unread: false,
                              );
                            }),
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

  Widget _buildChatListCard(String userName, String currentUserId, String role, String toUserId, {bool isOnline = false, bool unread = false}) {
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
                  child: _buildDefaultAvatar(userName),
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
