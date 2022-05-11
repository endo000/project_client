import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import '../controllers/RoadController.dart';
import 'SendDataScreen.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  late MapController mapController;

  updateTraffic() {
    RoadController.getTraffic().then((roads) {
      for (var road in roads) {
        GeoPoint point =
            GeoPoint(latitude: road["pos_y"], longitude: road["pos_x"]);
        mapController.addMarker(point);
      }
    });
  }

  @override
  void initState() {
    mapController = MapController(
      initMapWithUserPosition: true,
    );
    updateTraffic();
    super.initState();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant IndexScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
    updateTraffic();
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main page'),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          OSMFlutter(
            controller: mapController,
            trackMyPosition: true,
            initZoom: 12,
            androidHotReloadSupport: true,
            stepZoom: 1.0,
            userLocationMarker: UserLocationMaker(
              personMarker: const MarkerIcon(
                icon: Icon(
                  Icons.location_history_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              directionArrowMarker: const MarkerIcon(
                icon: Icon(
                  Icons.double_arrow,
                  size: 48,
                ),
              ),
            ),
            roadConfiguration: RoadConfiguration(
              startIcon: const MarkerIcon(
                icon: Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.brown,
                ),
              ),
              roadColor: Colors.yellowAccent,
            ),
            markerOption: MarkerOption(
                defaultMarker: const MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: Colors.blue,
                size: 56,
              ),
            )),
          ),
          ElevatedButton(
            child: const Text('Start sending'),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SendDataScreen()));
            },
          ),
        ],
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
