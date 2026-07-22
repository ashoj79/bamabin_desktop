import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketHelper {
  static io.Socket? _socket;

  static io.Socket get socket {
    final current = _socket;
    if (current == null) {
      throw StateError('Socket is not connected');
    }
    return current;
  }

  static bool get hasSocket => _socket != null;

  static void connect(String url) {
    disconnect();
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  static void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }
}
