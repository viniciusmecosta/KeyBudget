import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imageBase64;
  final String imageName;

  const ImageViewerScreen({
    super.key,
    required this.imageBase64,
    required this.imageName,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PhotoViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.imageName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_left),
            onPressed: () {
              _controller.rotation -= 90;
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: () {
              _controller.rotation += 90;
            },
          ),
        ],
      ),
      body: PhotoView(
        controller: _controller,
        imageProvider: MemoryImage(base64Decode(widget.imageBase64)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}
