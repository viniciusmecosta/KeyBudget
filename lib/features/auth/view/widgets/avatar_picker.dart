import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? initialImagePath;

  const AvatarPicker({
    super.key,
    required this.onImageSelected,
    this.initialImagePath,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _imageBase64 = widget.initialImagePath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      imageQuality: 70,
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
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundImage: _getImageProvider(),
        child: _imageBase64 == null
            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
            : null,
      ),
    );
  }
}
