import 'dart:io';
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
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _image = File(widget.initialImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      widget.onImageSelected(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundImage: _image != null ? FileImage(_image!) : null,
        child: _image == null
            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
            : null,
      ),
    );
  }
}
