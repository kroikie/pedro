import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedro/pedro_screens/game_lobby.dart';
import 'package:pedro/pedro_screens/game_round.dart';
import 'package:pedro/pedro_screens/game_summary.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../settings/settings.dart';
import '../style/palette.dart';

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();
    final Stream<DocumentSnapshot> gameStream = FirebaseFirestore.instance.doc('games/$gameId').snapshots();

    return StreamBuilder(
        stream: gameStream,
        builder: (context, snapshot) {
          final gameStatus = snapshot.data?.get('status');
          final gameName = snapshot.data?.get('name');
          final gameOwner = snapshot.data?.get('owner');

          switch(gameStatus) {
            case 'lobby':
              return GameLobby(gameId: gameId, gameName: gameName, gameOwner: gameOwner);
            case 'play':
              return GameRound(gameId: gameId, roundId: 'roundId');
            case 'summary':
              return GameSummary(gameId: gameId);
            default:
              return GameSummary(gameId: gameId);
          }
        }
    );
    return Scaffold(
      backgroundColor: palette.backgroundMain,
      appBar: AppBar(
        backgroundColor: palette.backgroundMain,
        title: const Text('Pedro Game'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: gameStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading game');
          }

          if (!snapshot.hasData) {
            return const Text('Loading...');
          }

          final name = snapshot.data?.get('name');
          return Center(child: Text(name));
        },
      ),
    );
  }
}
