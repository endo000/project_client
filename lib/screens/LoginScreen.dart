import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:project/controllers/UserController.dart';

import '../main.dart';
import 'IndexScreen.dart';

enum AuthType { login, singin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.type = AuthType.login, Key? key}) : super(key: key);

  final AuthType type;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  CameraController? controller;

  bool? logged;

  final _formKey = GlobalKey<FormState>();
  OverlayEntry? entry;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller!.description);
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: widget.type == AuthType.login
              ? const Text('Log in')
              : const Text('Sign up'),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView(
                children: <Widget>[
                  // Title
                  const Text(
                    'Project task',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 30),
                  ),
                  // Username text field
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }

                        if (logged != null && !logged!) {
                          return '';
                        }

                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                      ),
                    ),
                  ),
                  // Password text field
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      obscureText: true,
                      controller: passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }

                        if (logged != null && !logged!) {
                          return 'Wrong username or password';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                  ),
                  // Login / Sign up button
                  Container(
                      height: 50,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: ElevatedButton(
                        child: widget.type == AuthType.login
                            ? const Text('Login')
                            : const Text('Sign up'),
                        onPressed: () async {
                          logged = null;

                          if (!_formKey.currentState!.validate()) return;

                          if (widget.type == AuthType.login) {
                            logged = await UserController.login(
                                nameController.text, passwordController.text,
                                openCameraCallback: showOverlay);
                          } else {
                            logged = await UserController.register(
                              nameController.text,
                              passwordController.text,
                            );
                          }

                          if (logged!) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => IndexScreen()));
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _formKey.currentState!.validate();
                          }
                        },
                      )),
                  // Container(
                  //     height: 50,
                  //     padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  //     child: ElevatedButton(
                  //         child: const Text('Show camera'),
                  //         onPressed: showOverlay)),
                  if (widget.type == AuthType.login)
                    Row(
                      children: <Widget>[
                        const Text('Does not have account?'),
                        TextButton(
                          child: const Text(
                            'Sign in',
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(type: AuthType.singin),
                              ),
                            );
                            //signup screen
                          },
                        )
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                ],
              )),
        ));
  }

  Future<bool> showOverlay() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final overlay = Overlay.of(context)!;

    await onNewCameraSelected(cameras[1]);

    double size = MediaQuery.of(context).size.width;

    Completer<bool> loggedCompleter = Completer();
    bool logged;

    entry = OverlayEntry(
        builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: size,
                      height: size,
                      child: ClipOval(
                          child: OverflowBox(
                              child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: SizedBox(
                                      width: size,
                                      child: CameraPreview(controller!))))),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                            child: const Text('Close camera'),
                            onPressed: () {
                              entry!.remove();
                              controller?.dispose();
                            }),
                        ElevatedButton(
                            child: const Text('Take photo'),
                            onPressed: () async {
                              if (controller!.value.isTakingPicture) {
                                return;
                              }

                              XFile file = await controller!.takePicture();

                              logged = await UserController.login(
                                  nameController.text, passwordController.text,
                                  imagePath: file.path);

                              loggedCompleter.complete(logged);
                              entry!.remove();
                              controller?.dispose();
                            }),
                      ],
                    ),
                  ]),
            ));

    overlay.insert(entry!);

    return loggedCompleter.future;
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    final CameraController cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Camera error ${cameraController.value.errorDescription}')));
      }
    });

    try {
      await cameraController.initialize();
      // The exposure mode is currently not supported on the web.

    } on CameraException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code}\n${e.description}')));
    }

    if (mounted) {
      setState(() {});
    }
  }
}
