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
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = gameOwner == userId;

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
                ) : const SizedBox.shrink(),
                isOwner ? StreamBuilder(
                  stream: playersRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final playerDocs = snapshot.data!.docs;
                    var acceptedCount = 0;
                    for (QueryDocumentSnapshot<Map<String, dynamic>> playerDoc in playerDocs) {
                      if (playerDoc.data().containsKey('status') && playerDoc.get('status') == 'accepted') {
                        acceptedCount++;
                      }
                    }
                    if (acceptedCount >= 5) {
                      return IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.start),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ) : const SizedBox.shrink(),
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
                    trailing: getPlayerTrailing(snapshot, gameOwner, userId),
                  );
                },
              ),
            ),
          ],
        ));
  }

  Widget? getPlayerTrailing(QueryDocumentSnapshot<Map<String, dynamic>> snapshot, String ownerId, String userId) {
    final status = snapshot.data()['status'];
    if (ownerId == userId) {
      // user is the owner of the game
      if (userId != snapshot.id) {
        // The owner is viewing another player so return their current choice if it exists and the option to delete
        List<Widget> youths = [];
        if (status == 'accepted') {
          youths.add(const IconButton(onPressed: null, icon: Icon(Icons.check)));
        } else if (status == 'rejected') {
          youths.add(const IconButton(onPressed: null, icon: Icon(Icons.cancel)));
        }
        youths.add(getDeleteButton(snapshot.id));
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: youths,
        );
      }
    } else {
      // user is not the owner of the game, so only viewing their choice options
      if (userId == snapshot.id) {
        IconButton? acceptedOption;
        IconButton? rejectedOption;
        if (status == 'accepted') {
          acceptedOption = const IconButton(onPressed: null, icon: Icon(Icons.check));
          rejectedOption = IconButton(onPressed: rejectInvitation, icon: const Icon(Icons.cancel));
        } else if (status == 'rejected') {
          acceptedOption = IconButton(onPressed: acceptInvitation, icon: const Icon(Icons.check));
          rejectedOption = const IconButton(onPressed: null, icon: Icon(Icons.cancel));
        } else {
          acceptedOption = IconButton(onPressed: acceptInvitation, icon: const Icon(Icons.check));
          rejectedOption = IconButton(onPressed: rejectInvitation, icon: const Icon(Icons.cancel));
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            acceptedOption,
            rejectedOption
          ],
        );
      }
    }
    return null;
  }

  Future<void> acceptInvitation() async {
    final acceptCall = FirebaseFunctions.instance.httpsCallable('rsvp');
    await acceptCall.call({
      'gid': gameId,
      'choice': 'accepted',
    });
  }

  Future<void> rejectInvitation() async {
    final rejectCall = FirebaseFunctions.instance.httpsCallable('rsvp');
    await rejectCall.call({
      'gid': gameId,
      'choice': 'rejected',
    });
  }

  IconButton getDeleteButton(String playerId) {
    return IconButton(
      onPressed: () async {
        final removeCall = FirebaseFunctions.instance.httpsCallable('removePlayer');
        await removeCall.call({
          'pid': playerId,
          'gid': gameId
        });
      },
      icon: const Icon(Icons.delete),
    );
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
