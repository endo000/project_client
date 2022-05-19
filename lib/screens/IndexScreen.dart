import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import '../controllers/RoadController.dart';
import 'SendDataScreen.dart';

class ExamplePopup extends StatelessWidget {
  const ExamplePopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min, children: const [Text("asdasd")]),
      ),
    );
  }
}

class Road {
  Road(
      {required this.posX,
      required this.posY,
      required this.avgSpeed,
      required this.avgGap,
      required this.avgTraffic});

  final double posX;
  final double posY;
  final int avgSpeed;
  final int avgGap;
  final int avgTraffic;
}

class TrafficMarker extends Marker {
  TrafficMarker({required this.road})
      : super(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          width: 40,
          height: 40,
          point: LatLng(road.posY, road.posX),
          builder: (_) => Icon(Icons.location_on_outlined,
              size: 40,
              color: road.avgTraffic >= 200 ? Colors.red : Colors.green),
        );

  final Road road;
}

class TrafficMarkerPopup extends StatelessWidget {
  const TrafficMarkerPopup({Key? key, required this.road}) : super(key: key);

  final Road road;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("Average gap: ${road.avgGap}"),
            Text("Average speed: ${road.avgSpeed}"),
            Text("Average traffic: ${road.avgTraffic}"),
          ],
        ),
      ),
    );
  }
}

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  final PopupController _popupLayerController = PopupController();
  final StreamController<List<Marker>> _streamController = StreamController();

  updateTraffic() {
    RoadController.getTraffic().then((roads) {
      List<Marker> newRoads = roads
          .map((road) => TrafficMarker(
                road: Road(
                    posX: road["pos_x"],
                    posY: road["pos_y"],
                    avgSpeed: road["avg_spd"],
                    avgGap: road["avg_gap"],
                    avgTraffic: road["avg_traffic"]),
              ))
          .toList();
      _streamController.sink.add(newRoads);
    });
  }

  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      print("Traffic stream ${timer.tick}");
      updateTraffic();
    });
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main page'),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FlutterMap(
            options: MapOptions(
              zoom: 8.0,
              center: LatLng(46.1512, 14.9955),
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              onTap: (_, __) => _popupLayerController
                  .hideAllPopups(), // Hide popup when the map is tapped.
            ),
            children: [
              TileLayerWidget(
                options: TileLayerOptions(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
              ),
              StreamBuilder<List<Marker>>(
                  stream: _streamController.stream,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Marker>> snapshot) {
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    if (snapshot.hasData) {
                      return PopupMarkerLayerWidget(
                        options: PopupMarkerLayerOptions(
                            popupController: _popupLayerController,
                            markers: snapshot.data!,
                            markerRotateAlignment:
                                PopupMarkerLayerOptions.rotationAlignmentFor(
                                    AnchorAlign.top),
                            popupBuilder:
                                (BuildContext context, Marker marker) {
                              if (marker is TrafficMarker) {
                                return TrafficMarkerPopup(road: marker.road);
                              }
                              return const Card(child: Text('Not a monument'));
                            }),
                      );
                    }
                    return const CircularProgressIndicator();
                  }),
            ],
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
