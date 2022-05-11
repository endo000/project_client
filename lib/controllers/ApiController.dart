import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiController {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> getSession() async {
    return {'cookie': (await _storage.read(key: 'cookie') ?? "No")};
  }

  static void setSession(cookie) {
    _storage.write(key: 'cookie', value: cookie);
  }

  static void setSessionFromResponse(response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      setSession((index == -1) ? rawCookie : rawCookie.substring(0, index));
    }
  }

  static void deleteSession() {
    _storage.delete(key: 'cookie');
  }
}
