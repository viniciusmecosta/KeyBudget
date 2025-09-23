import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? initialImagePath;
  final IconData placeholderIcon;
  final double radius;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.initialImagePath,
    this.placeholderIcon = Icons.add_a_photo,
    this.radius = 50,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _imageBase64 = widget.initialImagePath;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath) {
      setState(() {
        _imageBase64 = widget.initialImagePath;
      });
    }
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

    if (Uri.tryParse(_imageBase64!)?.isAbsolute == true) {
      return NetworkImage(_imageBase64!);
    }
    try {
      return MemoryImage(base64Decode(_imageBase64!));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        backgroundImage: _getImageProvider(),
        child: _imageBase64 == null
            ? Icon(
                widget.placeholderIcon,
                size: widget.radius,
                color: theme.colorScheme.secondary,
              )
            : null,
      ),
    );
  }
}
