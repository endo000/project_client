import 'package:flutter/material.dart';
import 'package:project/controllers/UserController.dart';

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

  final _formKey = GlobalKey<FormState>();

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
                  Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        'Project task',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            fontSize: 30),
                      )),
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
                        labelText: 'User Name',
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
                                saveUser: true);
                          } else {
                            await UserController.register(
                              nameController.text,
                              passwordController.text,
                            );
                          }

                          if (logged!) {
                            Navigator.pushReplacementNamed(context, '/index');
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
                            print('signup screen');
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
}
