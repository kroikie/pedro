import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_storage/firebase_ui_storage.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    this.radius = 50,
  });

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius),
      );
    }

    final isFirebaseStorage = avatarUrl!.startsWith('gs://') ||
        avatarUrl!.contains('firebasestorage.googleapis.com') ||
        avatarUrl!.startsWith('avatars/');

    if (isFirebaseStorage) {
      try {
        final ref = avatarUrl!.startsWith('avatars/')
            ? FirebaseStorage.instance.ref(avatarUrl!)
            : FirebaseStorage.instance.refFromURL(avatarUrl!);

        return SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: ClipOval(
            child: StorageImage(
              ref: ref,
              fit: BoxFit.cover,
              errorBuilder: (context, error, [stackTrace]) => _errorIcon(),
            ),
          ),
        );
      } catch (_) {
        return _errorIcon();
      }
    }

    return _buildImage(avatarUrl!);
  }

  Widget _buildImage(String url) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _errorIcon(),
        ),
      ),
    );
  }

  Widget _errorIcon() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.error, size: radius),
    );
  }
}
