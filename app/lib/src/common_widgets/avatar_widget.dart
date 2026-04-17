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
                             avatarUrl!.contains('firebasestorage.googleapis.com');

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: isFirebaseStorage
            ? StorageImage(
              ref: _getRefFromUrl(avatarUrl!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, [stackTrace]) => _errorIcon(),
            )            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _errorIcon(),
              ),
      ),
    );
  }

  Reference _getRefFromUrl(String url) {
    if (url.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(url);
    }
    return FirebaseStorage.instance.refFromURL(url);
  }

  Widget _errorIcon() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.error, size: radius),
    );
  }
}
