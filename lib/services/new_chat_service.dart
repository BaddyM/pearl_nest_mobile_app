import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NewChatService {
  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io(
      dotenv.env["API_BASE_URL"],
      IO.OptionBuilder().setTransports(['websocket']).setQuery({'userId': userId}).disableAutoConnect().build(),
    );

    socket.emit("register", userId);

    debugPrint("Socket Connected");

    socket.connect();
  }

  void disconnect() {
    debugPrint("Socket Disconnected");
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event) {
    socket.off(event);
  }
}
