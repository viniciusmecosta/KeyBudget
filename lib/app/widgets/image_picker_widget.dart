import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:key_budget/core/services/app_lock_service.dart';

class ImagePickerWidget extends ConsumerStatefulWidget {
  final Function(String) onImageSelected;
  final String? initialImagePath;
  final IconData placeholderIcon;
  final double radius;

  final ValueChanged<String>? onError;
  final VoidCallback? onImageRemoved;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.initialImagePath,
    this.placeholderIcon = Icons.add_a_photo,
    this.radius = 50,
    this.onError,
    this.onImageRemoved,
  });

  @override
  ConsumerState<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends ConsumerState<ImagePickerWidget> {
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
    final appLockService = ref.read(appLockServiceProvider);
    appLockService.beginExternalPick();
    try {
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
    } catch (e) {
      widget.onError?.call('Não foi possível carregar a imagem selecionada.');
    } finally {
      appLockService.endExternalPick();
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
    final avatar = GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.secondary.withAlpha(
          (255 * 0.1).round(),
        ),
        backgroundImage: _getImageProvider(),
        child: _imageBase64 == null || _imageBase64!.isEmpty
            ? Icon(
                widget.placeholderIcon,
                size: widget.radius,
                color: theme.colorScheme.secondary,
              )
            : null,
      ),
    );

    if (_imageBase64 == null || _imageBase64!.isEmpty) {
      return avatar;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: theme.colorScheme.error,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() {
                  _imageBase64 = null;
                });
                widget.onImageSelected('');
                widget.onImageRemoved?.call();
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
