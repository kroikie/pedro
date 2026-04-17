import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SignInScreen(
        providers: [
          GoogleProvider(clientId: 'dummy-client-id-for-emulator'),
        ],
        actions: [
          AuthStateChangeAction<UserCreated>((context, state) {
            Navigator.pushNamed(context, '/profile');
          }),
        ],
      ),
    );
  }
}
