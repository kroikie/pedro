import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/services/avatar_generation_service.dart';

class AiAvatarDialog extends StatefulWidget {
  const AiAvatarDialog({
    super.key,
    required this.uid,
    required this.screenName,
    this.avatarService,
    this.onAvatarSaved,
  });

  final String uid;
  final String screenName;
  final AvatarGenerationService? avatarService;
  final ValueChanged<String>? onAvatarSaved;

  @override
  State<AiAvatarDialog> createState() => _AiAvatarDialogState();
}

class _AiAvatarDialogState extends State<AiAvatarDialog> {
  late final AvatarGenerationService _service;
  AvatarCategory _selectedCategory = AvatarCategory.animal;
  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;
  Uint8List? _previewBytes;

  static const List<String> _animalPresets = [
    'Lion',
    'Wolf',
    'Fox',
    'Owl',
    'Bear',
    'Tiger',
    'Eagle',
    'Cheetah',
  ];

  static const List<String> _personPresets = [
    'Army woman',
    'Astronaut',
    'Gamer',
    'Detective',
    'Superhero',
    'Chef',
    'Pilot',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.avatarService ?? AvatarGenerationService();
    _promptController.text = _animalPresets.first;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(AvatarCategory category) {
    setState(() {
      _selectedCategory = category;
      _errorMessage = null;
      _previewBytes = null;
      _promptController.text = category == AvatarCategory.animal
          ? _animalPresets.first
          : _personPresets.first;
    });
  }

  Future<void> _generateAvatar() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter or select a description');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _previewBytes = null;
    });

    try {
      final bytes = await _service.generateAvatarBytes(
        category: _selectedCategory,
        prompt: text,
      );
      if (mounted) {
        setState(() {
          _previewBytes = bytes;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Generation failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _saveAvatar() async {
    if (_previewBytes == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final url = await _service.uploadAndSaveAvatar(
        uid: widget.uid,
        imageBytes: _previewBytes!,
        screenName: widget.screenName,
      );

      if (mounted) {
        widget.onAvatarSaved?.call(url);
        Navigator.of(context).pop(url);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not save avatar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = _selectedCategory == AvatarCategory.animal
        ? _animalPresets
        : _personPresets;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generate AI Avatar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: (_isGenerating || _isSaving)
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<AvatarCategory>(
                segments: const [
                  ButtonSegment(
                    value: AvatarCategory.animal,
                    label: Text('Animal'),
                    icon: Icon(Icons.pets),
                  ),
                  ButtonSegment(
                    value: AvatarCategory.person,
                    label: Text('Person'),
                    icon: Icon(Icons.face),
                  ),
                ],
                selected: {_selectedCategory},
                onSelectionChanged: (selection) => _onCategoryChanged(selection.first),
              ),
              const SizedBox(height: 16),
              Text(
                'Suggestions',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: presets.map((preset) {
                  final isSelected = _promptController.text.trim().toLowerCase() ==
                      preset.toLowerCase();
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _promptController.text = preset;
                          _errorMessage = null;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                enabled: !_isGenerating && !_isSaving,
                decoration: InputDecoration(
                  labelText: _selectedCategory == AvatarCategory.animal
                      ? 'Animal description'
                      : 'Person description',
                  hintText: _selectedCategory == AvatarCategory.animal
                      ? 'e.g. A fierce lion, cute panda'
                      : 'e.g. Army woman, astronaut',
                  prefixIcon: Icon(
                    _selectedCategory == AvatarCategory.animal
                        ? Icons.pets
                        : Icons.person_outline,
                  ),
                ),
              ),
              if (_selectedCategory == AvatarCategory.person) ...[
                const SizedBox(height: 6),
                Text(
                  'Person avatars are generated as stylized cartoon headshots with darker skin tones.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              if (_previewBytes != null) ...[
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_isGenerating || _isSaving) ? null : _generateAvatar,
                        child: const Text('Try Again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAvatar,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Set as Avatar'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateAvatar,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Generating avatar...' : 'Generate Avatar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
