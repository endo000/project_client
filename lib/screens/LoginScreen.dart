import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:project/controllers/UserController.dart';
import 'package:project/screens/CameraOverlay.dart';
import '../main.dart';
import 'IndexScreen.dart';

enum AuthType { login, singin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.type = AuthType.login, Key? key}) : super(key: key);

  final AuthType type;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool? logged;
  bool use2fa = false;
  Completer<bool>? loggedCompleter;

  final _formKey = GlobalKey<FormState>();
  OverlayEntry? entry;

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
                  if (widget.type == AuthType.singin)
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text('Use 2FA'),
                            Checkbox(
                              value: use2fa,
                              onChanged: (bool? value) {
                                setState(() {
                                  use2fa = value ?? false;
                                });
                              },
                            ), //
                          ]),
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
                            // logged = await showOverlay();
                            logged = await UserController.register(
                                nameController.text, passwordController.text,
                                openCameraCallback:
                                    use2fa ? showOverlay : null);
                          }

                          if (logged!) {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const IndexScreen()),
                                (Route<dynamic> route) => false);
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _formKey.currentState!.validate();
                          }
                        },
                      )),
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
    loggedCompleter = Completer();

    entry = OverlayEntry(
        maintainState: true,
        builder: (context) => CameraOverlay(
              // loggedCompleter: loggedCompleter,
              closeOverlay: _closeOverlay,
              onTakePicture: onTakePicture,
            ));

    overlay.insert(entry!);

    return loggedCompleter!.future;
  }

  onTakePicture(XFile file) async {
    if (widget.type == AuthType.login) {
      logged = await UserController.login(
          nameController.text, passwordController.text,
          imagePath: file.path);
    } else {
      logged = await UserController.register(
          nameController.text, passwordController.text,
          imagePath: file.path);
    }
    loggedCompleter!.complete(logged);
    _closeOverlay();
  }

  void _closeOverlay() {
    entry!.remove();
  }
}
