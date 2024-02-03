import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../settings/settings.dart';
import '../style/palette.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();
    final currentUser = FirebaseAuth.instance.currentUser!;
    final gamesRef = FirebaseFirestore.instance.collection('users/${currentUser.uid}/games');

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      appBar: AppBar(
        backgroundColor: palette.backgroundMain,
        actions: [
          IconButton(
              onPressed: (){
                settingsController.toggleMusicOn();
                print(settingsController.musicOn.value);
              },
              icon: const Icon(Icons.volume_mute)
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: CircleAvatar(
              backgroundImage: NetworkImage(currentUser.photoURL!),
            ),
          )
        ],
      ),
      body: FirestoreListView(
          query: gamesRef.orderBy('creation'),
          itemBuilder: (context, snapshot) {
            Map<String, dynamic> game = snapshot.data();
            return ListTile(
              onTap: () => GoRouter.of(context).push('/games/${snapshot.id}'),
              title: Center(child: Text(game['name'])),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final createGameRequest = FirebaseFunctions.instance.httpsCallable('createGame');
          final result = await createGameRequest.call<Map<String, dynamic>>();
          final newGameId = result.data['gameId'];
          GoRouter.of(context).push('/games/$newGameId');
        },
        backgroundColor: palette.ink,
        foregroundColor: palette.pen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
