import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart'; // Import for ChangeNotifier
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

class EddystoneUID {
  String namespaceId;
  String instanceId;
  String name;
  int rssi;

  EddystoneUID({
    required this.namespaceId,
    required this.instanceId,
    required this.name,
    required this.rssi,
  });

  factory EddystoneUID.fromAdvertisment(Uint8List data, String name, int rssi) {
    String namespaceId = data
        .sublist(2, 12)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    String instanceId = data
        .sublist(12, 18)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return EddystoneUID(
      namespaceId: namespaceId,
      instanceId: instanceId,
      name: name,
      rssi: rssi,
    );
  }
}

class EddystoneScanner extends ChangeNotifier {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  Map<String, EddystoneUID> eddystoneUIDs = {};
  Timer? scanTimer;
  bool refresh = false;

  Future<void> requestPermissions() async {
    if (refresh) {
      // If permissions have been granted already, do nothing
      return;
    }

    await Permission.locationWhenInUse.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    if (await Permission.locationWhenInUse.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      refresh = true;
      startPeriodicScan();
    } else {
      print('Necessary permissions not granted');
    }
  }

  void startPeriodicScan() {
    if (scanTimer?.isActive ?? false) {
      // If scan timer is already active, do nothing
      return;
    }
    scanTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      startScan();
    });
  }

  void startScan() {
    print('Starting scan...');
    eddystoneUIDs.clear();
    flutterBlue.startScan(timeout: Duration(seconds: 8));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        var serviceData = result.advertisementData.serviceData;
        String deviceName = result.advertisementData.localName ?? 'Unknown';
        int rssi = result.rssi;

        serviceData.forEach((uuid, data) {
          if (data.isNotEmpty) {
            String hexData = data
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join();
            print('Hex data: $hexData');

            try {
              var uid = EddystoneUID.fromAdvertisment(
                  Uint8List.fromList(data), deviceName, rssi);

              if (uid.namespaceId == "ffffffff00000000ffff") {
                eddystoneUIDs[uid.namespaceId] = uid;
                notifyListeners(); // Notify listeners when data is updated
              }
            } catch (e) {
              print('Error decoding Eddystone UID frame: $e');
            }
          }
        });
      }
    });
  }

  void dispose() {
    scanTimer?.cancel();
    super.dispose(); // Make sure to call super.dispose()
  }
}
