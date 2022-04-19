import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'controllers/UserController.dart';
import 'screens/IndexScreen.dart';
import 'screens/LoginScreen.dart';

List<CameraDescription> cameras = <CameraDescription>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // UserController.deleteSession();

  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Project 2022'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Future<bool> isLogged = UserController.isLogged();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: isLogged,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              WidgetsBinding.instance!.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => snapshot.data!
                          ? const IndexScreen()
                          : const LoginScreen()),
                );
              });
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
