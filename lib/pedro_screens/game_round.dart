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
        stream: CombineLatestStream.combine4(
          FirebaseFirestore.instance.doc('games/$gameId').snapshots(),
          FirebaseFirestore.instance.doc('games/$gameId/rounds/$roundId').snapshots(),
          FirebaseFirestore.instance.doc('games/$gameId/rounds/$roundId/players/${user.uid}').snapshots(),
          FirebaseFirestore.instance.collection('games/$gameId/players').snapshots(),
          (a, b, c, d) => <String, dynamic>{
            'game': a,
            'round': b,
            'player': c,
            'players': d,
          }),
        builder: (context, snapshots) {
          if (!snapshots.hasData) {
            return const Center(child: Text('loading...'));
          }
          final gameSnapshot = snapshots.data!['game'];
          final roundSnapshot = snapshots.data!['round'];
          final playerSnapshot = snapshots.data!['player'];
          QuerySnapshot<Map<String, dynamic>> playersSnapshot = snapshots.data!['players'];

          final playerNickName = playerSnapshot.get('nick-name');
          List<dynamic> playerHand = playerSnapshot.get('hand');
          List<PlayingCardWidget> cardsInHand = [];
          for (int num in playerHand) {
            cardsInHand.add(PlayingCardWidget(PlayingCard.fromInt(num)));
          }

          List<PedroPlayerWidget> playerAvatars = [];
          var pos = 1;
          for (QueryDocumentSnapshot<Map<String, dynamic>> playerDoc in playersSnapshot.docs) {
            if (playerDoc.id == 'AfWKSQCVG9mr3D12OOZzRVUgz0Zh') continue;
            final photoUrl = playerDoc.get('photo-url');
            final nickName = playerDoc.get('nick-name');
            const score = 'score: 10';
            playerAvatars.add(PedroPlayerWidget(playerPhotoUrl: photoUrl, playerNickName: nickName, playerScore: score, pwa: (pos == 3 || pos == 5) ? PlayerWidgetAlignment.right : PlayerWidgetAlignment.left,));
            pos++;
          }

          return Column(
            children: [
              Center(child: Text(playerHand.toString())),
              PedroTableWidget(players: playerAvatars),
              Expanded(child: Container()),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        constraints: BoxConstraints(maxWidth: 60)
                    ),
                  ),
                  IconButton(
                      onPressed: () {

                      },
                      icon: const Icon(Icons.send)
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 10,
                  children: cardsInHand,
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

enum PlayerWidgetAlignment {
  left,
  right
}

class PedroPlayerWidget extends StatelessWidget {
  final String playerPhotoUrl;
  final String playerNickName;
  final String playerScore;
  final PlayerWidgetAlignment pwa;

  const PedroPlayerWidget({super.key, required this.playerPhotoUrl, required this.playerNickName,
    required this.playerScore, this.pwa = PlayerWidgetAlignment.left});

  @override
  Widget build(BuildContext context) {
    final picAndName = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(backgroundImage: NetworkImage(playerPhotoUrl)),
        Text(playerNickName)
      ],
    );

    if (pwa == PlayerWidgetAlignment.left) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [picAndName, Text(playerScore),],
      );
    } else {
      return Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text(playerScore), picAndName],);
    }
  }
}

class PedroTableWidget extends StatelessWidget {
  final List<PedroPlayerWidget> players;

  const PedroTableWidget({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [players.isNotEmpty ? players[0] : Container(),],
        ),
        Row(
            children: [
              players.length >= 2 ? players[1] : const SizedBox.shrink(),
              Expanded(child: Container(),),
              players.length >= 3 ? players[2] : const SizedBox.shrink(),
            ]
        ),
        Row(
            children: [
              players.length >= 4 ? players[3] : const SizedBox.shrink(),
              Expanded(child: Container(),),
              players.length >= 5 ? players[4] : const SizedBox.shrink(),
            ]
        ),
        Row(
            children: [
              players.length >= 6 ? players[5] : const SizedBox.shrink(),
              Expanded(child: Container(),),
              players.length >= 7 ? players[6] : const SizedBox.shrink(),
            ]
        ),
      ],
    );
  }
}


