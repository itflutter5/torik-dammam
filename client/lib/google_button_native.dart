import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Widget buildGoogleSignInButton() => OutlinedButton.icon(
  onPressed: () => GoogleSignIn.instance.authenticate(),
  icon: const Icon(Icons.account_circle_outlined),
  label: const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text('Continue with Google'),
  ),
);
