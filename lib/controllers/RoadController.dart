import 'dart:convert';

import 'package:http/http.dart' as http;

import '../consts.dart';
import 'ApiController.dart';

class RoadController {
  static Future<List> getTraffic() async {
    try {
      var response = await http.get(Uri.parse('http://$serverIP/traffic'));

      if (![200, 201].contains(response.statusCode)) return [];

      return jsonDecode(response.body) as List;
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<bool> sendData(Map geoInfo) async {
    var body = jsonEncode(geoInfo);

    try {
      var response =
          await http.post(Uri.parse('http://$serverIP/users/navigator'),
              body: body,
              headers: await ApiController.getSession()
                ..addAll({'Content-Type': 'application/json'}));

      if (![200, 201].contains(response.statusCode)) return false;

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static void finishData() async {
    try {
      await http.put(Uri.parse('http://$serverIP/users/navigator/finish'),
          headers: await ApiController.getSession());
    } catch (e) {
      print(e);
    }
  }
}
