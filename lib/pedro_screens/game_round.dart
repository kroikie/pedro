import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedro/play_session/playing_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../game_internals/playing_card.dart';
import '../style/palette.dart';

class GameRound extends StatelessWidget {
  final String gameId;
  final String gameName;
  final String roundId;

  const GameRound({super.key, required this.gameId, required this.gameName, required this.roundId});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.backgroundMain,
        title: Text(gameName),
      ),
      body: StreamBuilder(
        stream: CombineLatestStream.list([
          FirebaseFirestore.instance.doc('games/$gameId').snapshots(),
          FirebaseFirestore.instance.doc('games/$gameId/rounds/$roundId').snapshots(),
          FirebaseFirestore.instance.doc('games/$gameId/rounds/$roundId/players/${user.uid}').snapshots(),
        ]),
        builder: (context, snapshots) {
          if (!snapshots.hasData) {
            return const Center(child: Text('loading...'));
          }
          final gameSnapshot = snapshots.data![0];
          final roundSnapshot = snapshots.data![1];
          final playerSnapshot = snapshots.data![2];

          final playerNickName = playerSnapshot.get('nick-name');
          final playerHand = playerSnapshot.get('hand');
          return Column(
            children: [
              Center(child: Text(playerHand.toString())),
              Center(child: PlayingCardWidget(PlayingCard.fromInt(playerHand[3]))),
            ],
          );
        },
      ),
    );
  }
}
