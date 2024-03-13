import 'package:flutt/main.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';
import 'package:flutt/sensor_data.dart';

SensorData_list sensor_list = SensorData_list();

class WebSocketService with ChangeNotifier {
  late IOWebSocketChannel _channel;
  String _connectionStatus = 'Disconnected';
  late StreamController<Map<String, dynamic>> _messageController2;

  WebSocketService() {
    _messageController2 = StreamController<Map<String, dynamic>>.broadcast();
    _connectToWebSocket();
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController2.stream;

  void _connectToWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(
          'ws://firealert.waziwazi.top:8880?token=1234');
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
          _messageController2.add(data);
          notifyListeners();
        },
        onDone: () {
          _connectionStatus = 'Disconnected';
          notifyListeners();
        },
        onError: (error) {
          _connectionStatus = 'Disconnected';
          print('WebSocket Error: $error');
          notifyListeners();
        },
      );
    } catch (e) {
      // WebSocket连接失败，捕获异常并打印错误消息
      print('WebSocket Connection Error: $e');
    }
  }
}
