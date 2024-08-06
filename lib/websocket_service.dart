import 'package:flutt/main.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutt/sensor_data.dart';

SensorData_list sensor_list = SensorData_list();

class WebSocketService with ChangeNotifier {
  late IOWebSocketChannel? _channel;
  late StreamController<Map<String, dynamic>> _messageController;
  bool _isConnected = false;
  bool _bypassWebSocket = false;

  WebSocketService(Map<String, dynamic> token) {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    if (!kDebugMode) {
      _connectToWebSocket(token);
    } else {
      _bypassWebSocket = true;
      print('WebSocket bypassed in debug mode');
      _connectToWebSocket(token); //測試沒有驗證
    }
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  void _connectToWebSocket(Map<String, dynamic> token) async {
    //if (_bypassWebSocket) return;//測試沒有驗證

    while (!_isConnected) {
      try {
        final String url = _buildWebSocketUrl(token);
        _channel = IOWebSocketChannel.connect(url);

        _channel!.stream.listen(
          (message) {
            var data = json.decode(message.toString());
            if (data['status'] == 'success') {
              print('Connection established successfully');
              _isConnected = true;
            }
            print(message);
            _messageController.add(data);
            notifyListeners();
          },
          onError: (error) {
            print('WebSocket Error: $error');
            _isConnected = false;
          },
          onDone: () {
            print('WebSocket connection closed');
            _isConnected = false;
            _reconnect(token);
          },
        );

        break;
      } catch (e) {
        print('WebSocket Connection Error: $e');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  String _buildWebSocketUrl(Map<String, dynamic> token) {
    if (token.isEmpty) {
      return 'ws://firealert.waziwazi.top:8880?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huIiwiaWF0IjoxNzE1MDc2MDAxLCJleHAiOjE3MzA2MjgwMDF9.5sV4-QHxKTsg6MgoJ6CXaMuk_LacQaptPXSolqMnZL4&uid=10011';
    } else {
      String accessToken = token['accessToken'].toString();
      String uid = token['uid'].toString();
      return 'ws://firealert.waziwazi.top:8880?token=$accessToken&uid=$uid';
    }
  }

  void _reconnect(Map<String, dynamic> token) {
    if (!_bypassWebSocket) {
      Future.delayed(Duration(seconds: 5), () => _connectToWebSocket(token));
    }
  }

  void toggleBypassWebSocket(bool bypass) {
    _bypassWebSocket = bypass;
    if (!_bypassWebSocket && !_isConnected) {
      _connectToWebSocket({}); // Reconnect with empty token, adjust as needed
    }
    notifyListeners();
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
    super.dispose();
  }
}
