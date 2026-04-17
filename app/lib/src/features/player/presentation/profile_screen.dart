import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/player_repository.dart';
import '../domain/player.dart';
import '../../../common_widgets/avatar_widget.dart';

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

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    setState(() => _isLoading = true);
    try {
      _player = await _repository.getPlayer(uid);
      if (_player != null) {
        _nameController.text = _player!.displayName;
      }
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
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      
      if (kIsWeb) {
        await ref.putData(await pickedFile.readAsBytes());
      } else {
        await ref.putFile(File(pickedFile.path));
      }
      
      final url = await ref.getDownloadURL();
      final updatedPlayer = Player(
        id: uid,
        displayName: _nameController.text.isNotEmpty ? _nameController.text : 'Anonymous',
        avatarUrl: url,
      );
      
      await _repository.updatePlayer(updatedPlayer);
      setState(() => _player = updatedPlayer);
      
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

    setState(() => _isLoading = true);
    try {
      final updatedPlayer = Player(
        id: uid,
        displayName: _nameController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: AvatarWidget(
                    avatarUrl: _player?.avatarUrl,
                    radius: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tap to change avatar'),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
        ),
    );
  }
}
