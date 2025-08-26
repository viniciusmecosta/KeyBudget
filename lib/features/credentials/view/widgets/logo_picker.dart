import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LogoPicker extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? initialImagePath;

  const LogoPicker({
    super.key,
    required this.onImageSelected,
    this.initialImagePath,
  });

  @override
  State<LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends State<LogoPicker> {
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null &&
        widget.initialImagePath!.isNotEmpty) {
      _imageBase64 = widget.initialImagePath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 150,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(imageBytes);
      setState(() {
        _imageBase64 = base64String;
      });
      widget.onImageSelected(base64String);
    }
  }

  ImageProvider? _getImageProvider() {
    if (_imageBase64 == null || _imageBase64!.isEmpty) return null;

    if (_imageBase64!.startsWith('http')) {
      return NetworkImage(_imageBase64!);
    }

    return MemoryImage(base64Decode(_imageBase64!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        backgroundImage: _getImageProvider(),
        child: _imageBase64 == null
            ? Icon(Icons.add_photo_alternate_outlined,
                size: 30, color: theme.colorScheme.secondary)
            : null,
      ),
    );
  }
}
