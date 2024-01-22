import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';

class GameLobby extends StatelessWidget {
  final String gameId;
  final String gameName;
  final String gameOwner;

  const GameLobby({super.key, required this.gameId, required this.gameName, required this.gameOwner});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playersRef =
        FirebaseFirestore.instance.collection('games/$gameId/players');
    final isOwner = gameOwner == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: palette.backgroundMain,
          title: Text(gameName),
        ),
    body: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Players'),
            isOwner ? IconButton(
                onPressed: () async {
                  final selectedPlayer = await showSearch<Player?>(
                    context: context,
                    delegate: PlayerSearch(),
                  );
                  if (selectedPlayer != null) {
                    final addPlayerRequest = FirebaseFunctions.instance.httpsCallable('addPlayer');
                    await addPlayerRequest.call(<String, dynamic>{
                      'pid': selectedPlayer.uid,
                      'gid': gameId,
                    });
                  }
                },
                icon: const Icon(Icons.add)
            ) : Container(),
          ],
        ),
        Expanded(
          child: FirestoreListView(
            query: playersRef,
            itemBuilder: (context, snapshot) {
              Map<String, dynamic> player = snapshot.data();
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(player['photo-url'])),
                title: Text(player['nick-name']),
                trailing: snapshot.id == gameOwner ?
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.delete),
                    ):
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                    ),
              );
            },
          ),
        ),
      ],
    ));
  }
}

class Player {
  final String uid;
  final String nickName;
  final String photoUrl;

  Player(this.uid, this.nickName, this.photoUrl);
}

class PlayerSearch extends SearchDelegate<Player?> {
  List<Player> results = [];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () async {
            query = '';
          },
          icon: const Icon(Icons.close)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('users')
          .where(
              Filter.or(
                Filter('nick-name', isEqualTo: query),
                Filter('display-name', isEqualTo: query),
              )
          )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('there are no results');
        }
        final resultPlayers = snapshot.data!.docs.map((e) {
          return Player(e.id, e.get('nick-name'), e.get('photo-url'));
        }).toList();
        return ListView.builder(
          itemCount: resultPlayers.length,
          itemBuilder: (context, index) {
            final player = resultPlayers[index];
            return ListTile(
              onTap: () {
                close(context, player);
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(player.photoUrl),
              ),
              title: Text(player.nickName),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
