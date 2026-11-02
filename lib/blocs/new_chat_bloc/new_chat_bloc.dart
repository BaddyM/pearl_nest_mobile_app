import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/services/chat_cache_service.dart';
import 'package:pearlnest/services/new_chat_service.dart';
import 'package:uuid/uuid.dart';

part 'new_chat_event.dart';
part 'new_chat_state.dart';

class NewChatBloc extends Bloc<NewChatEvent, NewChatState> {
  final NewChatService socket;
  final String userId;
  String? _activePeerId;
  String? _activePropertyId;
  Map<String, dynamic>? _pendingMessage;
  String? _acknowledgedClientMessageId;
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
    socket.on('messageDelivered', (data) {
      if (data is Map) {
        final clientMessageId = data['clientMessageId']?.toString();
        if (clientMessageId != null &&
            clientMessageId == _pendingMessage?['clientMessageId']) {
          _pendingMessage = null;
          _acknowledgedClientMessageId = clientMessageId;
        }
      }
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
      final timestamp = DateTime.parse(json['createdAt'].toString());
      final status =
          json['isRead'] == true ? MessageStatus.seen : MessageStatus.sent;

      return TextMessage(
        id: json['id'].toString(),
        authorId: json['fromUserId'].toString(),
        createdAt: timestamp,
        status: status,
        text: json['message']?.toString() ?? '',
      );
    }

    Message convertCachedMessage(Map<String, dynamic> json) {
      final status = json['status'] == MessageStatus.seen.name
          ? MessageStatus.seen
          : MessageStatus.sent;
      return TextMessage(
        id: json['id']?.toString() ?? const Uuid().v4(),
        authorId: json['authorId']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
        status: status,
        text: json['text']?.toString() ?? '',
      );
    }

    Map<String, dynamic> cachedMessage(TextMessage textMessage) {
      return {
        'id': textMessage.id,
        'authorId': textMessage.authorId,
        'createdAt': textMessage.createdAt?.toIso8601String(),
        'status': textMessage.status?.name,
        'text': textMessage.text,
      };
    }

    Future<void> saveChatCache(
      String peerId,
      String? propertyId,
      List<Message> messages,
      String conversationStatus, {
      Map<String, dynamic>? pendingMessage,
    }
    ) async {
      try {
        await ChatCacheService.saveMessages(
          userId,
          peerId,
          propertyId,
          {
            'messages': messages
                .whereType<TextMessage>()
                .map(cachedMessage)
                .toList(),
            'conversationStatus': conversationStatus,
            if (pendingMessage != null) 'pendingMessage': pendingMessage,
          },
        );
      } catch (error, trace) {
        debugPrint('Could not save chat messages locally: $error\n$trace');
      }
    }

    Future<void> saveChatListCache(
      List<Map<String, dynamic>> conversations, {
      required bool isAdminList,
    }) async {
      try {
        await ChatCacheService.saveConversationList(
          userId,
          conversations,
          isAdminList: isAdminList,
        );
      } catch (error, trace) {
        debugPrint('Could not save the chat list locally: $error\n$trace');
      }
    }

    on<FetchNewChat>((event, emit) async {
      Map<String, dynamic>? cachedConversation;
      List<Message> cachedMessages = [];
      var cachedStatus = 'OPEN';
      var isSameConversation = false;
      try {
        if (event.isSendMessage == true) {
          _activePeerId = event.toUserId;
          _activePropertyId = event.propertyId;
          if (state is NewChatLoadedState) {
            final currentState = state as NewChatLoadedState;
            final clientMessageId =
                event.sendMessage?['clientMessageId']?.toString() ??
                    const Uuid().v4();
            final outgoingMessage = {
              ...?event.sendMessage,
              'clientMessageId': clientMessageId,
            };
            _pendingMessage = outgoingMessage;
            _acknowledgedClientMessageId = null;
            final newMessage = TextMessage(
              id: clientMessageId,
              authorId: event.sendMessage?["fromUserId"],
              createdAt: DateTime.now(),
              status: MessageStatus.sent,
              text: event.sendMessage?["text"],
            );
            final updatedMessages = currentState.messages
                .where((message) => message.id != clientMessageId)
                .toList()
              ..add(newMessage);

            emit(NewChatLoadedState(
              messages: updatedMessages,
              dateTime: DateTime.now(),
              conversationStatus: currentState.conversationStatus,
              pendingMessage: outgoingMessage,
            ));
            await saveChatCache(
              event.toUserId,
              event.propertyId,
              updatedMessages,
              currentState.conversationStatus,
              pendingMessage: outgoingMessage,
            );

            if (!socket.emit('sendMessage', outgoingMessage)) {
              add(ChatSocketErrorEvent(
                'Message not sent. Check your connection and retry.',
              ));
            } else {
              unawaited(Future<void>.delayed(
                const Duration(seconds: 20),
                () {
                  if (!isClosed &&
                      _pendingMessage?['clientMessageId'] == clientMessageId) {
                    add(ChatSocketErrorEvent(
                      'Message delivery is taking too long. You can retry it.',
                    ));
                  }
                },
              ));
            }
          }
        } else {
          isSameConversation = _activePeerId == event.toUserId &&
              _activePropertyId == event.propertyId &&
              state is NewChatLoadedState;
          if (!isSameConversation) emit(NewChatLoadingState());
          _activePeerId = event.toUserId;
          _activePropertyId = event.propertyId;
          cachedConversation = await ChatCacheService.readMessages(
            userId,
            event.toUserId,
            event.propertyId,
          );
          final cachedRows = cachedConversation?['messages'];
          if (cachedConversation != null && cachedRows is! List) {
            debugPrint('Cached chat messages had an invalid format.');
            cachedConversation = null;
          } else if (cachedRows is List) {
            cachedMessages = cachedRows
                .whereType<Map>()
                .map((row) => convertCachedMessage(
                      Map<String, dynamic>.from(row),
                    ))
                .toList();
          }
          cachedStatus =
              cachedConversation?['conversationStatus']?.toString() ?? 'OPEN';
          final cachedPending = cachedConversation?['pendingMessage'];
          final pendingMessage = cachedPending is Map
              ? Map<String, dynamic>.from(cachedPending)
              : null;
          final pendingId = pendingMessage?['clientMessageId']?.toString();
          final unresolvedPending =
              pendingId != null && pendingId == _acknowledgedClientMessageId
                  ? null
                  : pendingMessage;
          _pendingMessage = unresolvedPending;
          if (cachedConversation != null) {
            emit(NewChatLoadedState(
              messages: cachedMessages,
              dateTime: DateTime.now(),
              conversationStatus: cachedStatus,
              pendingMessage: unresolvedPending,
            ));
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
            final refreshedMessages = unresolvedPending == null
                ? chatMessages
                : [
                    ...chatMessages,
                    ...cachedMessages.where((message) => message.id == pendingId),
                  ];
            try {
              await ApiClient.patchWithoutData(
                "/chat/readMessage/${event.toUserId}/$userId$propertyQuery",
              );
            } catch (error) {
              debugPrint('Could not mark opened chat messages as read: $error');
            }
            emit(NewChatLoadedState(
              messages: refreshedMessages,
              dateTime: DateTime.now(),
              conversationStatus: conversationStatus,
              pendingMessage: unresolvedPending,
            ));
            await saveChatCache(
              event.toUserId,
              event.propertyId,
              refreshedMessages,
              conversationStatus,
              pendingMessage: unresolvedPending,
            );
            if (pendingId != null &&
                pendingId == _acknowledgedClientMessageId) {
              _acknowledgedClientMessageId = null;
            }
          } else {
            if (cachedConversation != null) {
              emit(NewChatLoadedState(
                messages: cachedMessages,
                dateTime: DateTime.now(),
                conversationStatus: cachedStatus,
                refreshError: 'Could not refresh chat. Showing saved messages.',
                pendingMessage: unresolvedPending,
              ));
            } else if (isSameConversation && state is NewChatLoadedState) {
              final current = state as NewChatLoadedState;
              emit(NewChatLoadedState(
                messages: current.messages,
                dateTime: DateTime.now(),
                conversationStatus: current.conversationStatus,
                refreshError: 'Could not refresh chat. Showing saved messages.',
                pendingMessage: current.pendingMessage,
              ));
            } else {
              emit(NewChatErrorState(error: "Sorry, failed to fetch chatlist"));
            }
          }
        }
      } catch (e, trace) {
        debugPrint("Error fetching chat: $e");
        debugPrint("Location: $trace");
        if (cachedConversation != null) {
          emit(NewChatLoadedState(
            messages: cachedMessages,
            dateTime: DateTime.now(),
            conversationStatus:
                cachedStatus,
            refreshError: 'Could not refresh chat. Showing saved messages.',
            pendingMessage: cachedConversation?['pendingMessage'] is Map
                ? Map<String, dynamic>.from(
                    cachedConversation!['pendingMessage'] as Map,
                  )
                : null,
          ));
        } else if (isSameConversation && state is NewChatLoadedState) {
          final current = state as NewChatLoadedState;
          emit(NewChatLoadedState(
            messages: current.messages,
            dateTime: DateTime.now(),
            conversationStatus: current.conversationStatus,
            refreshError: 'Could not refresh chat. Showing saved messages.',
            pendingMessage: current.pendingMessage,
          ));
        } else {
          emit(NewChatErrorState(error: "Sorry, failed to fetch chatlist"));
        }
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
            pendingMessage: current.pendingMessage,
          ),
        );
        final activePeerId = _activePeerId;
        if (activePeerId != null) {
          unawaited(saveChatCache(
            activePeerId,
            _activePropertyId,
            updatedMessages,
            current.conversationStatus,
            pendingMessage: current.pendingMessage,
          ));
        }
      }
    });

    on<ChatSocketErrorEvent>((event, emit) {
      if (state is NewChatLoadedState) {
        final current = state as NewChatLoadedState;
        final failed = _pendingMessage ?? current.pendingMessage;
        emit(NewChatLoadedState(
          messages: current.messages,
          dateTime: DateTime.now(),
          conversationStatus: current.conversationStatus,
          refreshError: event.message,
          pendingMessage: failed,
        ));
        final peerId = _activePeerId;
        if (peerId != null) {
          unawaited(saveChatCache(
            peerId,
            _activePropertyId,
            current.messages,
            current.conversationStatus,
            pendingMessage: failed,
          ));
        }
      } else {
        emit(NewChatErrorState(error: event.message));
      }
    });

    on<FetchNewChatList>((event, emit) async {
      Map<String, dynamic>? cachedList;
      try {
        if (state is! NewChatListLoadedState &&
            state is! NewChatListInitState) {
          emit(NewChatListLoadingState());
        }
        cachedList = await ChatCacheService.readConversationList(userId);
        final cachedData = cachedList?['data'];
        if (cachedData is List) {
          final data = cachedData
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          if (cachedList?['isAdminList'] == true) {
            emit(NewChatListInitState(data: data));
          } else {
            emit(NewChatListLoadedState(data: data));
          }
        }

        Response response = await ApiClient.get("/chat/chatList");
        List<Map<String, dynamic>> data;
        var isAdminList = false;
        if (response.statusCode == 200 || response.statusCode == 201) {
          data = List<Map<String, dynamic>>.from(response.data["data"]);
          if (data.isNotEmpty) {
            isAdminList = false;
          } else if (!event.loadAdminsIfEmpty) {
            data = const [];
          } else {
            Response adminResponse = await ApiClient.get("/chat/adminList");
            if (adminResponse.statusCode == 200 || adminResponse.statusCode == 201) {
              data = List<Map<String, dynamic>>.from(adminResponse.data["data"]);
              isAdminList = true;
            } else {
              throw StateError('Sorry, failed to fetch admin list');
            }
          }
        } else {
          throw StateError('Sorry, failed to fetch chatlist');
        }
        await saveChatListCache(data, isAdminList: isAdminList);
        if (isAdminList) {
          emit(NewChatListInitState(data: data));
        } else {
          emit(NewChatListLoadedState(data: data));
        }
      } catch (e) {
        debugPrint('Could not refresh the chat list: $e');
        final cachedData = cachedList?['data'];
        if (cachedData is List) {
          final data = cachedData
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          if (cachedList?['isAdminList'] == true) {
            emit(NewChatListInitState(
              data: data,
              refreshError: 'Could not refresh chats. Showing saved conversations.',
            ));
          } else {
            emit(NewChatListLoadedState(
              data: data,
              refreshError: 'Could not refresh chats. Showing saved conversations.',
            ));
          }
        } else {
          emit(NewChatListErrorState(error: "Sorry, failed to fetch chatlist"));
        }
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
