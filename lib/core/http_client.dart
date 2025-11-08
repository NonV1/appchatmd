import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  Api(this.baseUrl, this.storage);
  final String baseUrl;
  final FlutterSecureStorage storage;

  Future<Map<String, String>> _headers() async {
    final t = await storage.read(key: 'access_token');
    return {'content-type': 'application/json', if (t != null) 'authorization': 'Bearer $t'};
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
    return jsonDecode(res.body);
  }
}
 