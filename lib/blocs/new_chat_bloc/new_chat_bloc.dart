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
  String? _activePeerId;
  String? _activePropertyId;
  NewChatBloc(this.socket, this.userId) : super(NewChatInitial()) {
    // Listen to socket
    socket.on('sendMessage', (data) {
      if (data is Map &&
          _activePeerId != null &&
          (data['fromUserId'] == _activePeerId ||
              data['toUserId'] == _activePeerId) &&
          (data['propertyId'] ?? null) == _activePropertyId) {
        add(NewIncomingMessageEvent(Map<String, dynamic>.from(data)));
      }
    });

    socket.on('userOnline', (data) {
      debugPrint("userOnline: $data");
    });
    socket.on('chatError', (data) {
      add(ChatSocketErrorEvent(
        data is Map ? data['message']?.toString() ?? 'Message could not be sent.' : 'Message could not be sent.',
      ));
    });
    socket.on('messageDelivered', (_) {
      final peerId = _activePeerId;
      if (peerId != null) {
        add(FetchNewChat(
          currentUserId: userId,
          toUserId: peerId,
          propertyId: _activePropertyId,
        ));
      }
    });
    if (userId.isNotEmpty) socket.connect(userId);

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
        _activePeerId = event.toUserId;
        _activePropertyId = event.propertyId;
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
              conversationStatus: currentState.conversationStatus,
            ));

            // 3️⃣ Send to socket
            socket.emit('sendMessage', event.sendMessage);
          }
        } else {
          if (event.isSendMessage != true) {
            emit(NewChatLoadingState());
          }
          final propertyQuery = event.propertyId == null
              ? ''
              : '?propertyId=${Uri.encodeQueryComponent(event.propertyId!)}';
          Response response = await ApiClient.get(
            "/chat/messagesList/${event.toUserId}$propertyQuery",
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            final jsonList = response.data["data"] as List;
            final List<Message> chatMessages = List<Message>.from(jsonList.map((json) => convertToCoreMessage(json as Map<String, dynamic>)));
            final conversationStatus =
                response.data["conversationStatus"]?.toString() ?? 'OPEN';
            try {
              await ApiClient.patchWithoutData(
                "/chat/readMessage/${event.toUserId}/$userId$propertyQuery",
              );
            } catch (error) {
              debugPrint('Could not mark opened chat messages as read: $error');
            }
            emit(NewChatLoadedState(
              messages: chatMessages,
              dateTime: DateTime.now(),
              conversationStatus: conversationStatus,
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

        final senderId = event.data['fromUserId']?.toString();
        if (senderId != null &&
            event.data['toUserId']?.toString() == userId &&
            senderId == _activePeerId) {
          add(ReadMessageEvent(
            fromUserId: userId,
            toUserId: senderId,
            propertyId: _activePropertyId,
          ));
        }

        emit(
          NewChatLoadedState(
            messages: updatedMessages,
            dateTime: DateTime.now(),
            conversationStatus: current.conversationStatus,
          ),
        );
      }
    });

    on<ChatSocketErrorEvent>((event, emit) {
      emit(NewChatErrorState(error: event.message));
      final peerId = _activePeerId;
      if (peerId != null) {
        add(FetchNewChat(
          currentUserId: userId,
          toUserId: peerId,
          propertyId: _activePropertyId,
        ));
      }
    });

    on<FetchNewChatList>((event, emit) async {
      try {
        emit(NewChatListLoadingState());
        Response response = await ApiClient.get("/chat/chatList");
        if (response.statusCode == 200 || response.statusCode == 201) {
          final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response.data["data"]);
          if (data.isNotEmpty) {
            emit(NewChatListLoadedState(data: data));
          } else if (!event.loadAdminsIfEmpty) {
            emit(NewChatListLoadedState(data: const []));
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
        'fromUserId': event.fromUserId,
        'toUserId': event.toUserId,
        'message': event.message,
      });
    });

    on<ReadMessageEvent>((event, emit) async {
      try {
        final propertyQuery = event.propertyId == null
            ? ''
            : '?propertyId=${Uri.encodeQueryComponent(event.propertyId!)}';
        await ApiClient.patchWithoutData(
          "/chat/readMessage/${event.toUserId}/${event.fromUserId}$propertyQuery",
        );
      } catch (error) {
        debugPrint('Could not mark incoming chat messages as read: $error');
      }
    });
  }
}
