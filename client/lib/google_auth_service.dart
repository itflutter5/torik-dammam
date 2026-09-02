import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import 'api.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  bool _initialized = false;
  final _results = StreamController<String>.broadcast();

  Stream<String> get idTokens => _results.stream;

  Future<bool> initialize() async {
    if (_initialized) return true;
    final clientId = await ApiService.instance.fetchGoogleClientId();
    if (clientId.isEmpty) return false;
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: clientId,
    );
    GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final token = event.user.authentication.idToken;
        if (token != null) _results.add(token);
      }
    }, onError: _results.addError);
    _initialized = true;
    return true;
  }
}
