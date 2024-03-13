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
  //late StreamController<String> _messageController;
  late StreamController<Map<String, dynamic>> _messageController2;

  WebSocketService() {
    //_messageController = StreamController<String>.broadcast();
    _messageController2 = StreamController<Map<String, dynamic>>.broadcast();
    _connectToWebSocket();
  }
  //Stream<String> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController2.stream;
  void _connectToWebSocket() {
    _channel = IOWebSocketChannel.connect(
        'ws://firealert.waziwazi.top:8880?token=1234');
    _channel.stream.listen(
      (message) {
        var data = json.decode(message.toString());
        if (data['status'] == 'success') {
          _connectionStatus = 'Connected';
          //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          // SensorData sensorData;
          // Map<String, dynamic> jsonData = jsonDecode(message);
          // String updatetime = jsonData['0_update_stamp'];
          // String isAlert = jsonData['alert'].toString();
          // List<dynamic> details = jsonData['details'];
          // for (var detail in details) {
          //   String events = detail['event'];
          //   String levels = detail['level'].toString();
          //   String locations = detail['location'];
          //   String timestamps = detail['time_stamp'];
          //   Map<String, dynamic> sensors = detail['sensors'];
          //   String airqualitys = sensors['air_quality'].toStringAsFixed(2);
          //   String temperatures = sensors['temperature'].toStringAsFixed(2);
          // }
          // String id = '123';
          // String normals = 'Yes';
          // sensorData = SensorData(airqualitys, temperatures, id, normals,
          //     locations, events, isAlert, levels, updatetime);
          // sensor_list.add(sensorData);
          //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          print('Connection established successfully');
          print(message);
        } else {
          _connectionStatus = 'Disconnected';
          print(message);
        }
        //_messageController.add(message);
        _messageController2.add(data);
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

  SensorData_list getSensorData() {
    return sensor_list;
  }
}
