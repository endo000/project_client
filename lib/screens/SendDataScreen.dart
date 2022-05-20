import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:async/async.dart';

import '../controllers/RoadController.dart';

class SendDataScreen extends StatefulWidget {
  const SendDataScreen({Key? key}) : super(key: key);

  @override
  State<SendDataScreen> createState() => _SendDataScreenState();
}

class _SendDataScreenState extends State<SendDataScreen> {


  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    // distanceFilter: 100,
    // timeLimit: Duration(seconds: 5),
  );

  late Timer _dataTimer;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Position? position;
  UserAccelerometerEvent? accelerometer;
  MagnetometerEvent? magnetometer;

  Map? get data {
    if (position == null) return null;
    if (accelerometer == null) return null;
    if (magnetometer == null) return null;

    return {
      "position": {
        "latitude": position!.latitude,
        "longitude": position!.longitude,
        "speed": position!.speed,
      },
      "accelerometer": {
        "x": accelerometer!.x,
        "y": accelerometer!.y,
        "z": accelerometer!.z
      },
      "magnetometer": {
        "x": magnetometer!.x,
        "y": magnetometer!.y,
        "z": magnetometer!.z
      }
    };
  }

  @override
  void initState() {
    _dataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      print("Send data ${timer.tick}");

      if (data != null) RoadController.sendData(data!);
    });

    _streamSubscriptions.addAll([
      Geolocator.getPositionStream().listen((event) {
        setState(() {
          print("locator stream");
          position = event;
        });
      }),
      userAccelerometerEvents.listen((event) {
        setState(() {
          print("accelerometer stream");
          accelerometer = event;
        });
      }),
      magnetometerEvents.listen((event) {
        setState(() {
          print("magnetometer stream");
          magnetometer = event;
        });
      })
    ]);

    super.initState();
  }

  @override
  void dispose() {
    print("sendData dispose");
    _dataTimer.cancel();
    RoadController.finishData();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send data'),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Location: $position"),
            Text("Accelerometer: $accelerometer"),
            Text("Magnetometer: $magnetometer"),
          ],
        ),
      ),
    );
  }
}
