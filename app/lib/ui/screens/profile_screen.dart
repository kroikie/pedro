import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/models/player.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/app_version_footer.dart';
import '../widgets/ai_avatar_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = PlayerRepository();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  Player? _player;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      _player = await _repository.getPlayer(user.uid);
      final screenName = _player?.screenName;
      if (screenName != null && screenName.isNotEmpty) {
        _nameController.text = screenName;
      } else {
        final authDisplayName = user.displayName;
        _nameController.text = (authDisplayName != null && authDisplayName.isNotEmpty) 
            ? authDisplayName 
            : 'Anonymous';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarOptions() {
    final user = FirebaseAuth.instance.currentUser;
    final googlePhoto = user?.photoURL;
    final hasGooglePhoto = googlePhoto != null && googlePhoto.isNotEmpty;
    final isGooglePhotoCurrent = hasGooglePhoto && _player?.avatarUrl == googlePhoto;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Change Avatar',
                style: Theme.of(bottomSheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF8CFECE),
                  child: Icon(Icons.auto_awesome, color: Color(0xFF006145)),
                ),
                title: const Text('Generate AI Avatar'),
                subtitle: const Text('Create a cartoon animal or headshot'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _openAiAvatarDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFCA53),
                  child: Icon(Icons.photo_library, color: Color(0xFF5C4300)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Upload your own photo'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndUploadImage();
                },
              ),
              if (hasGooglePhoto && !isGooglePhotoCurrent)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF1EF),
                    child: Icon(Icons.account_circle, color: Color(0xFF00694B)),
                  ),
                  title: const Text('Use Google Profile Photo'),
                  subtitle: const Text('Reset avatar to your Google photo'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _useGooglePhoto(googlePhoto);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAiAvatarDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final screenName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Anonymous';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AiAvatarDialog(
        uid: uid,
        screenName: screenName,
        onAvatarSaved: (newUrl) {
          setState(() {
            _player = _player?.copyWith(avatarUrl: newUrl) ??
                Player(id: uid, screenName: screenName, avatarUrl: newUrl);
          });
        },
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Avatar updated successfully!')),
      );
    }
  }

  Future<void> _useGooglePhoto(String photoUrl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedPlayer = Player(
        id: uid,
        screenName: _nameController.text.isNotEmpty ? _nameController.text : 'Anonymous',
        avatarUrl: photoUrl,
      );
      await _repository.updatePlayer(updatedPlayer);
      setState(() => _player = updatedPlayer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated from Google profile!')),
        );
      }
    } catch (e) {
      debugPrint('Error setting Google photo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref().child('avatars/${uid}_$timestamp.jpg');
      
      if (kIsWeb) {
        await ref.putData(
          await pickedFile.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(
          File(pickedFile.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }
      
      final url = await ref.getDownloadURL();
      final updatedPlayer = Player(
        id: uid,
        screenName: _nameController.text.isNotEmpty ? _nameController.text : 'Anonymous',
        avatarUrl: url,
      );
      
      await _repository.updatePlayer(updatedPlayer);
      setState(() => _player = updatedPlayer);

      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final screenName = _nameController.text.trim();
    if (screenName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedPlayer = Player(
        id: uid,
        screenName: screenName,
        avatarUrl: _player?.avatarUrl,
      );
      await _repository.updatePlayer(updatedPlayer);
      setState(() => _player = updatedPlayer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            AvatarWidget(
                              avatarUrl: _player?.avatarUrl,
                              radius: 50,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _showAvatarOptions,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Change avatar'),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Screen Name'),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Profile'),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      const AppVersionFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
