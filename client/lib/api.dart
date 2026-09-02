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
  Map<String, dynamic>? currentUser;

  Future<bool> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString('auth_token');
    final savedUser = preferences.getString('auth_user');
    if (savedUser != null) {
      currentUser = jsonDecode(savedUser) as Map<String, dynamic>;
    }
    return token != null;
  }

  Future<void> _saveSession(String value, Map<String, dynamic> user) async {
    token = value;
    currentUser = user;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_token', value);
    await preferences.setString('auth_user', jsonEncode(user));
  }

  Future<Map<String, dynamic>> startRegistration({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String storeNumber,
    required String verificationMethod,
  }) async {
    return _jsonRequest('/auth/register/start', {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'storeNumber': storeNumber,
      'verificationMethod': verificationMethod,
    });
  }

  Future<void> verifyRegistration({
    required String verificationId,
    required String code,
  }) async {
    final data = await _jsonRequest('/auth/register/verify', {
      'verificationId': verificationId,
      'code': code,
    });
    await _saveSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>,
    );
  }

  Future<void> login({required String phone, required String password}) async {
    final data = await _jsonRequest('/auth/login', {
      'phone': phone,
      'password': password,
    });
    await _saveSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> startPasswordReset(String identifier) =>
      _jsonRequest('/auth/password-reset/start', {'identifier': identifier});

  Future<void> verifyPasswordReset({
    required String verificationId,
    required String code,
    required String newPassword,
  }) async {
    await _jsonRequest('/auth/password-reset/verify', {
      'verificationId': verificationId,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<String> fetchGoogleClientId() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/config'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) return '';
    return data['googleClientId'] as String? ?? '';
  }

  Future<void> loginWithGoogle(String idToken) async {
    final data = await _jsonRequest('/auth/google', {'idToken': idToken});
    await _saveSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>,
    );
  }

  Future<void> signOut() async {
    token = null;
    currentUser = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token');
    await preferences.remove('auth_user');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/auth/me'),
      headers: {'authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load profile');
    }
    final user = data['user'] as Map<String, dynamic>;
    currentUser = user;
    await (await SharedPreferences.getInstance()).setString(
      'auth_user',
      jsonEncode(user),
    );
    return user;
  }

  Future<Map<String, dynamic>> updateStoreNumber(String storeNumber) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/users/me'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({'storeNumber': storeNumber}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not save profile');
    }
    final user = data['user'] as Map<String, dynamic>;
    currentUser = user;
    await (await SharedPreferences.getInstance()).setString(
      'auth_user',
      jsonEncode(user),
    );
    return user;
  }

  Future<Map<String, dynamic>> uploadProfileImage(UploadImage image) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$apiBaseUrl/users/me/image'),
    )..headers['authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('image', image.bytes, filename: image.name),
    );
    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not upload image');
    }
    final user = data['user'] as Map<String, dynamic>;
    currentUser = user;
    await (await SharedPreferences.getInstance()).setString(
      'auth_user',
      jsonEncode(user),
    );
    return user;
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

  Future<bool> createPost({
    required String category,
    required String title,
    required String description,
    required String price,
    required String unit,
    required String storeNumber,
    required List<UploadImage> images,
    UploadImage? paymentProof,
    String? paymentCurrency,
  }) async {
    if (token == null) throw const ApiException('Please log in again');
    final request =
        http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/posts'))
          ..headers['authorization'] = 'Bearer $token'
          ..fields.addAll({
            'category': category,
            'title': title,
            'description': description,
            'price': price,
            'unit': unit,
            'storeNumber': storeNumber,
            if (paymentCurrency != null) 'paymentCurrency': paymentCurrency,
          });
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          image.bytes,
          filename: image.name,
        ),
      );
    }
    if (paymentProof != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'paymentProof',
          paymentProof.bytes,
          filename: paymentProof.name,
        ),
      );
    }
    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not publish post');
    }
    return data['pendingApproval'] == true;
  }

  Future<Map<String, dynamic>> fetchPostQuota() async {
    if (token == null) throw const ApiException('Please log in again');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/posts/quota'),
      headers: {'authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load post quota');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchAdminPosts([String? status]) async {
    final query = status == null ? '' : '?status=$status';
    final response = await http.get(
      Uri.parse('$apiBaseUrl/admin/posts$query'),
      headers: {'authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load pending posts');
    }
    return (data['posts'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> reviewPost(String postId, bool approved) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/admin/posts/$postId/review'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({'approved': approved}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not review post');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/posts'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error'] as String? ?? 'Could not load posts');
    }
    return (data['posts'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    if (token == null) throw const ApiException('Please log in again');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/posts/mine'),
      headers: {'authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Could not load your posts',
      );
    }
    return (data['posts'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchSavedPosts() async {
    if (token == null) throw const ApiException('Please log in again');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/posts/saved'),
      headers: {'authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Could not load saved posts',
      );
    }
    return (data['posts'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> setPostSaved(String postId, bool saved) async {
    if (token == null) throw const ApiException('Please log in again');
    final uri = Uri.parse('$apiBaseUrl/posts/$postId/save');
    final response = saved
        ? await http.post(uri, headers: {'authorization': 'Bearer $token'})
        : await http.delete(uri, headers: {'authorization': 'Bearer $token'});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Could not update saved post',
      );
    }
  }

  Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Could not load categories',
      );
    }
    return (data['categories'] as List)
        .map((item) => (item as Map<String, dynamic>)['name'] as String)
        .toList();
  }
}
