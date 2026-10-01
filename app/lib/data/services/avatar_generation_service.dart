import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/player_repository.dart';
import '../models/player.dart';

enum AvatarCategory {
  animal,
  person,
}

class AvatarGenerationService {
  AvatarGenerationService({
    FirebaseAI? firebaseAI,
    FirebaseStorage? storage,
    PlayerRepository? playerRepository,
  })  : _customFirebaseAI = firebaseAI,
        _customStorage = storage,
        _customPlayerRepository = playerRepository;

  final FirebaseAI? _customFirebaseAI;
  final FirebaseStorage? _customStorage;
  final PlayerRepository? _customPlayerRepository;

  FirebaseAI get _firebaseAI =>
      _customFirebaseAI ??
      FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true);
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;
  PlayerRepository get _playerRepository =>
      _customPlayerRepository ?? PlayerRepository();

  GenerativeModel get _imageModel => _firebaseAI.generativeModel(
        model: 'gemini-3.1-flash-image',
      );

  String buildPrompt(AvatarCategory category, String description) {
    final trimmed = description.trim();
    switch (category) {
      case AvatarCategory.animal:
        return 'A vibrant modern cartoon avatar portrait of a $trimmed, '
            'stylized vector illustration, cute expressive character, '
            'clean circular frame composition, colorful solid background, '
            'video game profile badge, high quality digital art.';
      case AvatarCategory.person:
        return 'A stylized cartoon headshot avatar portrait of a $trimmed '
            'with beautiful dark skin tone (deep melanin, rich brown complexion), '
            'friendly expression, modern vector illustration, clean circular profile badge, '
            'colorful solid background, high quality digital character art.';
    }
  }

  Future<Uint8List> generateAvatarBytes({
    required AvatarCategory category,
    required String prompt,
  }) async {
    final engineeredPrompt = buildPrompt(category, prompt);

    try {
      final response = await _imageModel.generateContent(
        [Content.text(engineeredPrompt)],
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
          imageConfig: const ImageConfig(
            aspectRatio: ImageAspectRatio.square1x1,
            imageSize: ImageSize.size512,
          ),
        ),
      );

      final inlineParts = response.inlineDataParts.toList();
      if (inlineParts.isNotEmpty) {
        return inlineParts.first.bytes;
      }

      throw Exception('The AI model did not return any image data. Please try another description.');
    } catch (e, stack) {
      debugPrint('Error generating avatar with gemini-3.1-flash-image: $e');
      try {
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'AvatarGenerationService.generateAvatar failed',
          );
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<String> uploadAndSaveAvatar({
    required String uid,
    required Uint8List imageBytes,
    required String screenName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'avatars/${uid}_$timestamp.jpg';
    final ref = _storage.ref().child(path);

    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await ref.getDownloadURL();

    final updatedPlayer = Player(
      id: uid,
      screenName: screenName.isNotEmpty ? screenName : 'Anonymous',
      avatarUrl: downloadUrl,
    );

    await _playerRepository.updatePlayer(updatedPlayer);

    try {
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
    } catch (e) {
      debugPrint('Could not update Firebase Auth photoURL: $e');
    }

    return downloadUrl;
  }
}
