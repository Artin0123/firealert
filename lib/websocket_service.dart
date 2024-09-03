import 'package:flutt/main.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutt/sensor_data.dart';
import 'package:flutt/usersensor.dart';

SensorData_list sensor_list = SensorData_list();

class WebSocketService with ChangeNotifier {
  late IOWebSocketChannel? _channel;
  late StreamController<Map<String, dynamic>> _messageController;
  bool _isConnected = false;
  bool _bypassWebSocket = false;

  WebSocketService(Map<String, dynamic> token, Usersensor usersenser) {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    if (!kDebugMode) {
      _connectToWebSocket(token, usersenser);
    } else {
      _bypassWebSocket = true;
      print('WebSocket bypassed in debug mode');
      _connectToWebSocket(token, usersenser); //測試沒有驗證
    }
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  void _connectToWebSocket(
      Map<String, dynamic> token, Usersensor usersenser) async {
    //if (_bypassWebSocket) return;//測試沒有驗證

    Map<String, dynamic> bufferMessage;
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
            print(usersenser);
            bufferMessage = {
              'response': 'Macarean received successfully',
              'data': data,
              'adjust': {
                'name': usersenser.name,
                'group': usersenser.group,
                'start': usersenser.start,
                'smoke_limit': usersenser.smoke_limit,
                'smoke_sensitive': usersenser.smoke_limit,
                'tem_limit': usersenser.tem_limit,
                'hot_sensitive': usersenser.hot_sensitive,
                'video_length': usersenser.video_length
              }
            };
            _channel?.sink.add(json.encode(bufferMessage));
            notifyListeners();
          },
          onError: (error) {
            print('WebSocket Error: $error');
            _isConnected = false;
          },
          onDone: () {
            print('WebSocket connection closed');
            _isConnected = false;
            _reconnect(token, usersenser);
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

  void _reconnect(Map<String, dynamic> token, Usersensor usersenser) {
    if (!_isConnected) {
      Future.delayed(
          Duration(seconds: 5), () => _connectToWebSocket(token, usersenser));
    }
  }

  void toggleBypassWebSocket(bool bypass, Usersensor usersenser) {
    _bypassWebSocket = bypass;
    if (!_bypassWebSocket && !_isConnected) {
      _connectToWebSocket(
          {}, usersenser); // Reconnect with empty token, adjust as needed
    }
    notifyListeners();
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
    super.dispose();
  }
}
