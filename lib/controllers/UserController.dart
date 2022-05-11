import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../consts.dart';
import 'ApiController.dart';

class UserController {


  static Future<String> list() async {
    var response = await http.get(Uri.parse('http://$serverIP/users'),
        headers: await ApiController.getSession());

    if (response.statusCode != 200) {
      throw Exception('Failed to load title');
    }

    return response.body;
  }

  static Future<bool> login(username, password,
      {imagePath, openCameraCallback}) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://$serverIP/users/login'));
    request.fields['username'] = username;
    request.fields['password'] = password;

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
      ));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      ApiController.setSessionFromResponse(response);
      return true;
    } else if (response.statusCode == 401) {
      if (openCameraCallback != null) {
        return openCameraCallback();
      }
    }

    return false;
  }

  static Future<bool> register(username, password) async {
    var response = await http.post(Uri.parse('http://$serverIP/users/register'),
        body: {'username': username, 'password': password});

    if ([200, 201].contains(response.statusCode)) return false;

    ApiController.setSessionFromResponse(response);

    return true;
  }

  static Future<bool> isLogged() async {
    var response = await http.get(Uri.parse('http://$serverIP/users/auth'),
        headers: await ApiController.getSession());

    if (response.statusCode != 200) return false;

    return true;
  }
}
