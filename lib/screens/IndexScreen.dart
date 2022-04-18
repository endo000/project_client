import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../consts.dart';
import '../controllers/UserController.dart';

Future<String> fetchTitle() async {
  String address = 'http://$serverIP/users';
  debugPrint('Address $address');
  final response = await http.get(Uri.parse(address));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return response.body;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load title');
  }
}

class IndexScreen extends StatelessWidget {
  final Future<String> futureTitle = UserController.list();

  IndexScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: futureTitle,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }
}
