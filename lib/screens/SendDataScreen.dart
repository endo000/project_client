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
    // distanceFilter: 100,
    // timeLimit: Duration(seconds: 5),
  );

  late StreamSubscription positionStream;

  @override
  void initState() {

    positionStream =
        Geolocator.getPositionStream().listen((Position? position) {
      if (position == null) return;
      var info = {
        "pos_y": position.latitude,
        "pos_x": position.longitude,
        "speed": position.speed
      };
      RoadController.sendGeo(info);
    });
    // StreamZip([
    //   Geolocator.getPositionStream(),
    //   accelerometerEvents,
    //   userAccelerometerEvents,
    //   magnetometerEvents
    // ]).listen((p0) {
    //   print(p0);
    // });
    // accelerometerEvents.listen((event) {
    //   if (event != null) {
    //     print("listen in initState");
    //   }
    // });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    positionStream.cancel();

    RoadController.finishGeo();

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
            StreamBuilder<ServiceStatus>(
              stream: Geolocator.getServiceStatusStream(),
              initialData: ServiceStatus.enabled,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data! == ServiceStatus.disabled) {
                    return const Text('Location services are disabled.');
                  }

                  return FutureBuilder<LocationPermission>(
                    future: Geolocator.checkPermission(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data! == LocationPermission.denied) {
                          return FutureBuilder<LocationPermission>(
                            future: Geolocator.requestPermission(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                if (snapshot.data! ==
                                    LocationPermission.denied) {
                                  return const Text(
                                      'Location permissions are denied');
                                }
                              } else if (snapshot.hasError) {
                                return Text('${snapshot.error}');
                              }
                              // By default, show a loading spinner.
                              return const CircularProgressIndicator();
                            },
                          );
                        }
                        if (snapshot.data! ==
                            LocationPermission.deniedForever) {
                          // Permissions are denied forever, handle appropriately.
                          return const Text(
                              'Location permissions are permanently denied, we cannot request permissions.');
                        }
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      // By default, show a loading spinner.
                      return StreamBuilder<Position>(
                          stream: Geolocator.getPositionStream(
                              locationSettings: locationSettings),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              Position position = snapshot.data!;
                              return Text(
                                  '${position.latitude.toString()}, ${position.longitude.toString()}');
                            } else if (snapshot.hasError) {
                              return Text('${snapshot.error}');
                            }
                            return const CircularProgressIndicator();
                          });
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
            StreamBuilder<AccelerometerEvent>(
              stream: accelerometerEvents,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.toString());
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const CircularProgressIndicator();
              },
            ),
            StreamBuilder<GyroscopeEvent>(
              stream: gyroscopeEvents,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.toString());
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const CircularProgressIndicator();
              },
            ),
            StreamBuilder<MagnetometerEvent>(
              stream: magnetometerEvents,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.toString());
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }
}
