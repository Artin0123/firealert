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
  late StreamController<Map<String, dynamic>> _messageController2;

  WebSocketService(Map<String, dynamic> token) {
    _messageController2 = StreamController<Map<String, dynamic>>.broadcast();
    _connectToWebSocket(token);
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController2.stream;

  void _connectToWebSocket(Map<String, dynamic> token) async {
    while (true) {
      try {
        if (token.isEmpty) {
          _channel = IOWebSocketChannel.connect(
              'ws://firealert.waziwazi.top:8880?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huIiwiaWF0IjoxNzE1MDc2MDAxLCJleHAiOjE3MzA2MjgwMDF9.5sV4-QHxKTsg6MgoJ6CXaMuk_LacQaptPXSolqMnZL4&uid=10011');
        } else if (token.isNotEmpty) {
          String accessToken = token['accessToken'].toString();
          String uid = token['uid'].toString();
          _channel = IOWebSocketChannel.connect('ws://firealert.waziwazi.top:8880?token=' + accessToken + '&uid=' + uid);
        }

        // _channel = IOWebSocketChannel.connect(
        //     'ws://firealert.waziwazi.top:8880?token=1234');
        _channel.stream.listen(
          (message) {
            var data = json.decode(message.toString());
            if (data['status'] == 'success') {
              print('Connection established successfully');
              print(message);
            } else {
              print(message);
            }
            _messageController2.add(data);
            notifyListeners();
          },
          onError: (error) {
            print('WebSocket Error: $error');
          },
        );
        break;
      } catch (e) {
        print('WebSocket Connection Error: $e');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }
}
