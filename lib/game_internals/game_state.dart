import 'package:flutter/foundation.dart';

class GameState {
  final VoidCallback onWin;

  GameState({required this.onWin});
}

class Game {
  final DateTime creation;
  final String name;

  Game({required this.creation, required this.name});

  Game.fromJson(Map<String, Object?> json): this(
    creation: json['creation']! as DateTime,
    name: json['name']! as String,
  );

  Map<String, Object?> toJson() {
    return {
      'creation': creation,
      'name': name,
    };
  }
}
