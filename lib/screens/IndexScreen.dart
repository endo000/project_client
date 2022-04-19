import 'package:flutter/material.dart';

import 'SendDataScreen.dart';



class IndexScreen extends StatelessWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main page'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Start sending'),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const SendDataScreen()));
          },
        ),
      ),
    );
  }
}

/* class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');

      accelerometerEvents.listen((AccelerometerEvent event) {
        print(event);
      });
// [AccelerometerEvent (x: 0.0, y: 9.8, z: 0.0)]

      userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        print(event);
      });
// [UserAccelerometerEvent (x: 0.0, y: 0.0, z: 0.0)]

      gyroscopeEvents.listen((GyroscopeEvent event) {
        print(event);
      });
// [GyroscopeEvent (x: 0.0, y: 0.0, z: 0.0)]

      magnetometerEvents.listen((MagnetometerEvent event) {
        print(event);
      });
// [MagnetometerEvent (x: -23.6, y: 6.2, z: -34.9)]
    });

    super.initState();
  }
} */
