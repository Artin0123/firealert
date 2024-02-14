import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';

class WebSocketService with ChangeNotifier {
  late IOWebSocketChannel _channel;
  String _connectionStatus = 'Disconnected';
  late StreamController<String> _messageController;

  WebSocketService() {
    _messageController = StreamController<String>.broadcast();
    _connectToWebSocket();
  }
  Stream<String> get messageStream => _messageController.stream;
  void _connectToWebSocket() {
    _channel =
        IOWebSocketChannel.connect('ws://59.102.142.103:9988?token=1234');
    _channel.stream.listen(
      (message) {
        var data = json.decode(message.toString());
        if (data['status'] == 'success') {
          _connectionStatus = 'Connected';
          print('Connection established successfully');
          print(message);
        } else {
          _connectionStatus = 'Disconnected';
          print(message);
        }
        _messageController.add(message);
        notifyListeners();
      },
      onDone: () {
        _connectionStatus = 'Disconnected';
        notifyListeners();
      },
      onError: (error) {
        _connectionStatus = 'Disconnected';
        notifyListeners();
      },
    );
  }
}
