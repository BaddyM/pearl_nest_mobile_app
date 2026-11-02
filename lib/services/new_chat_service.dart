import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NewChatService {
  IO.Socket? _socket;
  String? _connectedUserId;
  final Map<String, List<Function(dynamic)>> _handlers = {};

  Future<void> connect(String userId) async {
    if (_socket?.connected == true && _connectedUserId == userId) return;
    _socket?.disconnect();
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('auth_token');
    if (token == null || token.isEmpty) return;

    _connectedUserId = userId;
    _socket = IO.io(
      dotenv.env["API_BASE_URL"],
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    for (final entry in _handlers.entries) {
      for (final handler in entry.value) {
        _socket!.on(entry.key, handler);
      }
    }
    _socket!.onConnect((_) => _socket!.emit('register', userId));
    _socket!.connect();
  }

  void disconnect() {
    debugPrint("Socket Disconnected");
    _socket?.disconnect();
  }

  bool emit(String event, dynamic data) {
    final socket = _socket;
    if (socket?.connected != true) return false;
    socket!.emit(event, data);
    return true;
  }

  void on(String event, Function(dynamic) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  void off(String event) {
    _handlers.remove(event);
    _socket?.off(event);
  }
}
