import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  late StreamSubscription<List<ScanResult>> _scanSubscription;

  Future scanDevices() async {
    var blePermission = await Permission.bluetoothScan.status;
    if (blePermission.isDenied) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          await _startContinuousScan();
        }
      }
    } else {
      await _startContinuousScan();
    }
  }

  Future _startContinuousScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Process the beacon data here
        print('${result.device.name} found! rssi: ${result.rssi}');
      }
    });
    FlutterBluePlus.startScan(
      timeout: Duration(minutes: 1), // Increase the scan duration
      androidUsesFineLocation: true,
    );
  }

  void stopScan() async {
    if (_scanSubscription != null) {
      await _scanSubscription.cancel();
      _scanSubscription = null!;
    }
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}
