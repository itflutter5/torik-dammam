import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:10000/api',
);

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UploadImage {
  const UploadImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class ApiService {
  ApiService._();
  static final instance = ApiService._();
  String? token;

  Future<bool> restoreSession() async {
    token = (await SharedPreferences.getInstance()).getString('auth_token');
    return token != null;
  }

  Future<void> _saveToken(String value) async {
    token = value;
    await (await SharedPreferences.getInstance()).setString('auth_token', value);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String storeNumber,
  }) async {
    final data = await _jsonRequest('/auth/register', {
      'name': name, 'phone': phone, 'password': password,
      'storeNumber': storeNumber,
    });
    await _saveToken(data['token'] as String);
  }

  Future<void> login({required String phone, required String password}) async {
    final data = await _jsonRequest('/auth/login', {
      'phone': phone, 'password': password,
    });
    await _saveToken(data['token'] as String);
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Request failed');
    }
    return data;
  }

  Future<void> createPost({
    required String category,
    required String title,
    required String description,
    required String price,
    required String unit,
    required String storeNumber,
    required List<UploadImage> images,
  }) async {
    if (token == null) throw const ApiException('Please log in again');
    final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/posts'))
      ..headers['authorization'] = 'Bearer $token'
      ..fields.addAll({
        'category': category, 'title': title, 'description': description,
        'price': price, 'unit': unit, 'storeNumber': storeNumber,
      });
    for (final image in images) {
      request.files.add(http.MultipartFile.fromBytes(
        'images', image.bytes, filename: image.name,
      ));
    }
    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not publish post');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/posts'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load posts');
    }
    return (data['posts'] as List)
        .cast<Map<String, dynamic>>();
  }

  Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load categories');
    }
    return (data['categories'] as List)
        .map((item) => (item as Map<String, dynamic>)['name'] as String)
        .toList();
  }
}
