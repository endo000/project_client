import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../consts.dart';

class UserController {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getSession() async {
    return {'cookie': (await _storage.read(key: 'cookie') ?? "No")};
  }

  static void _setSession(cookie) {
    _storage.write(key: 'cookie', value: cookie);
  }

  static void _setSessionFromResponse(response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      _setSession((index == -1) ? rawCookie : rawCookie.substring(0, index));
    }
  }

  static void deleteSession() {
    _storage.delete(key: 'cookie');
  }

  static Future<String> list() async {
    var response = await http.get(Uri.parse('http://$serverIP/users'),
        headers: await _getSession());

    if (response.statusCode != 200) {
      throw Exception('Failed to load title');
    }

    return response.body;
  }

  static Future<bool> login(username, password, {saveUser = false}) async {
    var response = await http.post(Uri.parse('http://$serverIP/users/login'),
        body: {'username': username, 'password': password});

    if (response.statusCode != 200) return false;

    _setSessionFromResponse(response);

    return true;
  }

  static Future<bool> register(username, password) async {
    var response = await http.post(Uri.parse('http://$serverIP/users/'),
        body: {'username': username, 'password': password});

    if (response.statusCode != 200) return false;

    return true;
  }

  static Future<bool> isLogged() async {
    var response = await http.get(Uri.parse('http://$serverIP/users/auth'),
        headers: await _getSession());

    if (response.statusCode != 200) return false;

    return true;
  }
}
