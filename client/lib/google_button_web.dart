import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleSignInButton() => Center(
  child: web.renderButton(
    configuration: GSIButtonConfiguration(
      type: GSIButtonType.standard,
      text: GSIButtonText.continueWith,
      size: GSIButtonSize.large,
      shape: GSIButtonShape.rectangular,
      minimumWidth: 300,
    ),
  ),
);
