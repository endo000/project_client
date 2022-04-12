import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../consts.dart';

class UserController {
  static const _storage = FlutterSecureStorage();

  static void _saveUser(username, password) {
    _storage.write(key: 'username', value: username);
    _storage.write(key: 'password', value: password);
  }

  static void logout() {
    _storage.delete(key: 'username');
    _storage.delete(key: 'password');
  }

  static Future<bool> login(username, password, {saveUser = false}) async {
    var response = await http.post(Uri.parse('http://$serverIP/users/login'),
        body: {'username': username, 'password': password});

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) return false;

    if (saveUser) _saveUser(username, password);

    return true;
  }

  static Future<bool> register(username, password) async {
    var response = await http.post(Uri.parse('http://$serverIP/users/register'),
        body: {'username': username, 'password': password});

    if (response.statusCode != 200) return false;

    return true;
  }

  static Future<bool> isLogged() async {
    String? username = await _storage.read(key: 'username');
    String? password = await _storage.read(key: 'password');

    if (username == null || password == null) return false;

    return await login(username, password);
  }
}
