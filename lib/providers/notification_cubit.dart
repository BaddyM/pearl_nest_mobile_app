import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationCubit extends Cubit<int> {
  late IO.Socket _socket;

  NotificationCubit() : super(0); // Initial unread count is 0

  Future<void> initSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    _socket = IO.io(
      dotenv.env["API_BASE_URL"],
      IO.OptionBuilder().setTransports(['websocket']).setQuery({'userId': userId}).build(),
    );

    _socket.onConnect((_) => print('Connected to Socket'));

    // Listen for the event we defined in NestJS
    _socket.on('unread_count', (data) {
      final count = data['count'] as int;
      emit(count); // This updates the UI automatically
    });
  }

  @override
  Future<void> close() {
    _socket.dispose();
    return super.close();
  }
}
