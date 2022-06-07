import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../controllers/RoadController.dart';
import 'SendDataScreen.dart';

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

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  final PopupController _popupLayerController = PopupController();

  late Timer _dataTimer;
  late Timer _trafficTimer;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Position? position;
  Position? oldPosition;
  bool positionRefreshed = false;

  UserAccelerometerEvent? accelerometer;
  MagnetometerEvent? magnetometer;

  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;

  bool isSending = false;
  String? roadStatusText;
  List<TrafficMarker> _markers = [];

  Future<bool> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return true;
  }

  updateTraffic() {
    RoadController.getTraffic().then((roads) {
      setState(() {
        _markers = roads
            .map((road) => TrafficMarker(
                  road: Road(
                      posX: road["pos_x"],
                      posY: road["pos_y"],
                      avgSpeed: road["avg_spd"],
                      avgGap: road["avg_gap"],
                      avgTraffic: road["avg_traffic"]),
                ))
            .toList();
      });
    });
  }

  @override
  void initState() {
    updateTraffic();
    _trafficTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      print("Traffic stream ${timer.tick}");
      updateTraffic();
    });
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
    super.initState();
  }

  @override
  void dispose() {
    _trafficTimer.cancel();
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main page'),
      ),
      body: FlutterMap(
        options: MapOptions(
          zoom: 13.0,
          center: LatLng(46.1512, 14.9955),
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          onTap: (_, __) => _popupLayerController
              .hideAllPopups(), // Hide popup when the map is tapped.
          onPositionChanged: (MapPosition position, bool hasGesture) {
            if (hasGesture) {
              setState(
                () => _centerOnLocationUpdate = CenterOnLocationUpdate.never,
              );
            }
          },
        ),
        children: [
          TileLayerWidget(
            options: TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
          ),
          LocationMarkerLayerWidget(
            plugin: LocationMarkerPlugin(
              centerCurrentLocationStream:
                  _centerCurrentLocationStreamController.stream,
              centerOnLocationUpdate: _centerOnLocationUpdate,
            ),
          ),
          PopupMarkerLayerWidget(
            options: PopupMarkerLayerOptions(
                popupController: _popupLayerController,
                markers: _markers,
                markerRotateAlignment:
                    PopupMarkerLayerOptions.rotationAlignmentFor(
                        AnchorAlign.top),
                popupBuilder: (BuildContext context, Marker marker) {
                  if (marker is TrafficMarker) {
                    return TrafficMarkerPopup(road: marker.road);
                  }
                  return const Card(child: Text('Not a monument'));
                }),
          ),
        ],
        nonRotatedChildren: [
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Automatically center the location marker on the map when location updated until user interact with the map.
                setState(
                  () => _centerOnLocationUpdate = CenterOnLocationUpdate.always,
                );
                // Center the location marker on the map and zoom the map to level 18.
                _centerCurrentLocationStreamController.add(18);
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: ElevatedButton(
              child: Text(isSending ? 'Stop sending' : 'Start sending'),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: startSending,
            ),
          ),
          if (isSending) Positioned(left: 20, top: 20, child: dataColumn),
        ],
      ),
    );
  }

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

  _sendData() {
    if (oldPosition == position || data == null) return;

    RoadController.sendData(data!);
    oldPosition = position;

    setState(() {
      if (accelerometer == null) {
        roadStatusText = "Unknown";
      } else if (accelerometer!.z < 1) {
        roadStatusText = "Very good";
      } else if (accelerometer!.z < 2.4) {
        roadStatusText = "Good";
      } else if (accelerometer!.z < 3.5) {
        roadStatusText = "Moderate";
      } else {
        roadStatusText = "Bad";
      }
    });
  }

  void startSending() {
    setState(() {
      isSending = !isSending;
    });
    if (isSending) {
      _streamSubscriptions.addAll([
        Geolocator.getPositionStream().listen((event) {
          setState(() {
            position = event;
          });
        }),
        userAccelerometerEvents.listen((event) {
          setState(() {
            accelerometer = event;
          });
        }),
        magnetometerEvents.listen((event) {
          setState(() {
            magnetometer = event;
          });
        })
      ]);

      _sendData();
      _dataTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) => _sendData());
    } else {
      _dataTimer.cancel();
      RoadController.finishData();
      for (final subscription in _streamSubscriptions) {
        subscription.cancel();
      }
    }
  }

  Column get dataColumn {
    const style = TextStyle(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Speed: " + (position?.speed.toStringAsFixed(2) ?? "null"),
            style: style),
        Text("Road condition: " + (roadStatusText ?? "Unknown"), style: style),
        Text("X: " + (accelerometer?.x.toStringAsFixed(2) ?? "null"),
            style: style),
        Text("Y: " + (accelerometer?.y.toStringAsFixed(2) ?? "null"),
            style: style),
        Text("Z: " + (accelerometer?.z.toStringAsFixed(2) ?? "null"),
            style: style),
      ],
    );
  }
}

class TrafficMarker extends Marker {
  TrafficMarker({required this.road})
      : super(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          width: 40,
          height: 40,
          point: LatLng(road.posY, road.posX),
          builder: (_) => Icon(Icons.location_on,
              size: 20,
              color: road.avgTraffic >= 200 ? Colors.red : Colors.green),
        );

  final Road road;
}

class TrafficMarkerPopup extends StatelessWidget {
  const TrafficMarkerPopup({Key? key, required this.road}) : super(key: key);

  final Road road;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
