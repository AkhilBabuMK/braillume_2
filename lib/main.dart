import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, Map<String, dynamic>> iBeaconDataMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BRAILLUME"),
        centerTitle: true,
      ),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (controller) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () => controller.scanDevices(),
                  child: Text("Scan"),
                ),
                SizedBox(
                  height: 15,
                ),
                StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      snapshot.data!.forEach((data) {
                        final deviceName = data.device.name;
                        final deviceId = data.device.id.id;
                        final rssi = data.rssi.toString();
                        final iBeaconData = parseIBeaconData(
                            data.advertisementData, deviceName, deviceId, rssi);
                        if (iBeaconData != null) {
                          iBeaconDataMap[iBeaconData['uuid']] = iBeaconData;
                          print(iBeaconDataMap);
                        }
                      });
                      return Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: iBeaconDataMap.values.map((data) {
                              final deviceName = data['deviceName'];
                              final deviceId = data['deviceId'];
                              final rssi = data['rssi'];
                              final iBeaconData = data['iBeaconData'];

                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  title: Text(deviceName),
                                  subtitle: Text(
                                      '$deviceId - RSSI: $rssi\n$iBeaconData'),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    } else {
                      return Center(
                        child: Text("No Device Found"),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  // Rest of the code remains the same...

  Map<String, dynamic>? parseIBeaconData(
      AdvertisementData data, String deviceName, String deviceId, String rssi) {
    if (data.manufacturerData.containsKey(76)) {
      final iBeaconBytes = data.manufacturerData[76];
      print(iBeaconBytes);

      if (iBeaconBytes != null && iBeaconBytes.length >= 22) {
        final uuid = iBeaconBytes.sublist(2, 18);
        final major = iBeaconBytes.sublist(18, 20);
        final minor = iBeaconBytes.sublist(20, 22);

        final formattedUUID = uuidToString(uuid);
        final majorValue = bytesToInt(major);
        final minorValue = bytesToInt(minor);
        print(majorValue);
        print(minorValue);

        // Check if iBeacon data is already in the map
        final existingData = iBeaconDataMap[formattedUUID];

        if (existingData != null) {
          // Update the existing data
          existingData['major'] = majorValue;
          existingData['minor'] = minorValue;
          existingData['iBeaconData'] =
              'UUID: $formattedUUID Major: $majorValue Minor: $minorValue';
          return existingData;
        } else {
          // Add new data to the map
          return {
            'deviceName': deviceName,
            'deviceId': deviceId,
            'rssi': rssi,
            'iBeaconData':
                'UUID: $formattedUUID Major: $majorValue Minor: $minorValue',
            'major': majorValue,
            'minor': minorValue,
            'uuid': formattedUUID,
          };
        }
      }
    }
    return null;
  }

  String uuidToString(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }

    final formatted = buffer.toString();
    return '${formatted.substring(0, 8)}-${formatted.substring(8, 12)}-${formatted.substring(12, 16)}-${formatted.substring(16, 20)}-${formatted.substring(20, 32)}';
  }

  int bytesToInt(List<int> bytes) {
    int value = 0;
    for (final byte in bytes) {
      value = (value << 8) | byte;
    }
    return value;
  }
}
