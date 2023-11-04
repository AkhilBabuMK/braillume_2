import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  Future scanDevices() async {
    var blePermission = await Permission.bluetoothScan.status;
    if (blePermission.isDenied) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          _startContinuousScan();
        }
      }
    } else {
      _startContinuousScan();
    }
  }

  void _startContinuousScan() async {
    while (true) {
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
      FlutterBluePlus.startScan(
        timeout: Duration(seconds: 4),
        androidUsesFineLocation: true,
      );
      await Future.delayed(Duration(seconds: 4));
      FlutterBluePlus.stopScan(); // Stop the scan to avoid interference
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}
