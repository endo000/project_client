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
          builder: (_) => Icon(Icons.location_on,
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

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  final PopupController _popupLayerController = PopupController();
  late Timer _trafficTimer;

  List<TrafficMarker> _markers = [];

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
    _trafficTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      print("Traffic stream ${timer.tick}");
      updateTraffic();
    });
    super.initState();
  }

  @override
  void dispose() {
    print("index dispose");
    _trafficTimer.cancel();
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
