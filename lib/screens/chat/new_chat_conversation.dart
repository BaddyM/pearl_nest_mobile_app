import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/new_chat_bloc/new_chat_bloc.dart';
import 'package:pearlnest/utils/custom_snackbar.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/loading_widget.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

class NewChatConversation extends StatefulWidget {
  const NewChatConversation({super.key, required this.fromUserId, required this.toUserId, required this.userName});
  final String fromUserId;
  final String toUserId;
  final String userName;

  @override
  State<NewChatConversation> createState() => _NewChatConversationState();
}

class _NewChatConversationState extends State<NewChatConversation> {
  final _chatController = InMemoryChatController();
  var uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    //Read message
    context.read<NewChatBloc>().add(ReadMessageEvent(fromUserId: widget.fromUserId, toUserId: widget.toUserId));

    //Fetch conversation
    context.read<NewChatBloc>().add(FetchNewChat(currentUserId: widget.fromUserId, toUserId: widget.toUserId));
  }

  void _fetchChat() {
    context.read<NewChatBloc>().add(
          FetchNewChat(
            currentUserId: widget.fromUserId,
            toUserId: widget.toUserId,
          ),
        );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.read<NewChatBloc>().add(FetchNewChatList());
            Navigator.of(context).pop();
          },
        ),
        title: Text(widget.userName),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: _fetchChat,
            child: Icon(
              Icons.refresh,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: BlocConsumer<NewChatBloc, NewChatState>(builder: (context, state) {
        if (state is NewChatLoadingState) {
          return LoadingWidget();
        } else if (state is NewChatLoadedState) {
          return Chat(
            theme: ChatTheme(
              colors: ChatColors(
                primary: AppTheme.primaryblue, // sent bubble
                onPrimary: Colors.white, // Sent text color
                surface: Colors.grey.shade200, // Received bubble color
                onSurface: Colors.black, // Received text color
                surfaceContainer: Colors.white,
                surfaceContainerLow: Colors.grey.shade100,
                surfaceContainerHigh: Colors.grey.shade300,
              ),
              typography: ChatTypography.fromThemeData(Theme.of(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ).borderRadius,
            ),
            chatController: _chatController,
            currentUserId: widget.fromUserId,
            onMessageSend: (text) {
              context.read<NewChatBloc>().add(
                    FetchNewChat(currentUserId: widget.fromUserId, toUserId: widget.toUserId, isSendMessage: true, sendMessage: {
                      "fromUserId": widget.fromUserId,
                      "toUserId": widget.toUserId,
                      "text": text,
                    }),
                  );
            },
            resolveUser: (UserID id) async {
              return User(id: widget.fromUserId, name: widget.userName);
            },
          );
        } else {
          return SizedBox();
        }
      }, listener: (context, state) {
        if (state is NewChatErrorState) {
          CustomSnackBar.showError(context, "Sorry, failed to fetch message.");
        } else if (state is NewChatLoadedState) {
          _chatController.setMessages(state.messages);
        }
      }),
    );
  }
}
