import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/services/new_chat_service.dart';
import 'package:uuid/uuid.dart';

part 'new_chat_event.dart';
part 'new_chat_state.dart';

class NewChatBloc extends Bloc<NewChatEvent, NewChatState> {
  final NewChatService socket;
  final String userId;
  NewChatBloc(this.socket, this.userId) : super(NewChatInitial()) {
    socket.connect(userId);

    // Listen to socket
    socket.on('sendMessage', (data) {
      debugPrint("chatData: $data");
      debugPrint("toUserId: ${data["toUserId"]}");
      add(NewIncomingMessageEvent(data));
    });

    socket.on('userOnline', (data) {
      debugPrint("userOnline: $data");
    });

    Message convertToCoreMessage(Map<String, dynamic> json) {
      // 1. Convert Prisma ISO string to Milliseconds
      final DateTime timestamp = DateTime.parse(json['createdAt']);

      // 2. Map Status
      final MessageStatus status = json['isRead'] ? MessageStatus.seen : MessageStatus.sent;

      return TextMessage(
        id: json['id'],
        authorId: json['fromUserId'],
        createdAt: timestamp,
        status: status,
        text: json['message'],
      );
    }

    on<FetchNewChat>((event, emit) async {
      try {
        if (event.isSendMessage == true) {
          if (state is NewChatLoadedState) {
            final currentState = state as NewChatLoadedState;

            // 1️⃣ Create local message
            final newMessage = TextMessage(
              id: const Uuid().v4(),
              authorId: event.sendMessage?["fromUserId"],
              createdAt: DateTime.now(),
              status: MessageStatus.sent,
              text: event.sendMessage?["text"],
            );

            // 2️⃣ Add it immediately
            final updatedMessages = List<Message>.from(currentState.messages)..add(newMessage);

            emit(NewChatLoadedState(
              messages: updatedMessages,
              dateTime: DateTime.now(),
            ));

            // 3️⃣ Send to socket
            socket.emit('sendMessage', event.sendMessage);
          }
        } else {
          if (event.isSendMessage != true) {
            emit(NewChatLoadingState());
          }
          Response response = await ApiClient.get("/chat/messagesList/${event.toUserId}");
          if (response.statusCode == 200 || response.statusCode == 201) {
            final jsonList = response.data["data"] as List;
            final List<Message> chatMessages = List<Message>.from(jsonList.map((json) => convertToCoreMessage(json as Map<String, dynamic>)));
            emit(NewChatLoadedState(
              messages: chatMessages,
              dateTime: DateTime.now(),
            ));
          } else {
            emit(NewChatErrorState(error: "Sorry, failed to fetch chatlist"));
          }
        }
      } catch (e, trace) {
        print("Error: $e");
        print("Location: $trace");
        emit(NewChatErrorState(error: "Sorry, failed to fetch chatlist"));
      }
    });

    on<NewIncomingMessageEvent>((event, emit) {
      if (state is NewChatLoadedState) {
        final current = state as NewChatLoadedState;

        final newMessage = convertToCoreMessage(event.data);

        final updatedMessages = List<Message>.from(current.messages)..add(newMessage);

        emit(
          NewChatLoadedState(
            messages: updatedMessages,
            dateTime: DateTime.now(),
          ),
        );
      }
    });

    on<FetchNewChatList>((event, emit) async {
      try {
        bool userOnline = false;
        emit(NewChatListLoadingState());
        Response response = await ApiClient.get("/chat/chatList");
        if (response.statusCode == 200 || response.statusCode == 201) {
          final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response.data["data"]);
          if (data.isNotEmpty) {
            emit(NewChatListLoadedState(data: data));
          } else {
            Response adminResponse = await ApiClient.get("/chat/adminList");
            if (adminResponse.statusCode == 200 || adminResponse.statusCode == 201) {
              final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(adminResponse.data["data"]);
              emit(NewChatListInitState(data: data));
            } else {
              emit(NewChatListErrorState(error: "Sorry, failed to fetch admin list"));
            }
          }
        } else {
          emit(NewChatListErrorState(error: "Sorry, failed to fetch chatlist"));
        }
      } catch (e) {
        emit(NewChatListErrorState(error: "Sorry, failed to fetch chatlist"));
      }
    });

    on<SendMessageEvent>((event, emit) {
      socket.emit('sendMessage', {
        'toUserId': event.toUserId,
        'message': event.message,
      });
    });

    on<ReadMessageEvent>((event, emit) {});
  }
}
