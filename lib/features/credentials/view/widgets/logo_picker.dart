import 'dart:io';
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
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null &&
        widget.initialImagePath!.isNotEmpty) {
      _image = File(widget.initialImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

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
        radius: 40,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        backgroundImage: _image != null ? FileImage(_image!) : null,
        child: _image == null
            ? Icon(Icons.add_photo_alternate_outlined,
                size: 30,
                color: Theme.of(context).colorScheme.onSecondaryContainer)
            : null,
      ),
    );
  }
}
