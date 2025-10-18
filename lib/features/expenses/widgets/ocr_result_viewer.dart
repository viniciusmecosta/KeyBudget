import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResultViewer extends StatefulWidget {
  final String imagePath;
  final RecognizedText recognizedText;
  final ValueChanged<String> onTextBlockTap;

  const OcrResultViewer({
    super.key,
    required this.imagePath,
    required this.recognizedText,
    required this.onTextBlockTap,
  });

  @override
  State<OcrResultViewer> createState() => _OcrResultViewerState();
}

class _OcrResultViewerState extends State<OcrResultViewer> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _getImageSize();
  }

  Future<void> _getImageSize() async {
    final image = File(widget.imagePath);
    final decodedImage = await decodeImageFromList(image.readAsBytesSync());
    setState(() {
      _imageSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return _imageSize == null
        ? const Center(child: CircularProgressIndicator())
        : GestureDetector(
            onTapUp: (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final canvasSize = renderBox.size;
              final double scaleX = canvasSize.width / _imageSize!.width;
              final double scaleY = canvasSize.height / _imageSize!.height;

              for (final textBlock in widget.recognizedText.blocks) {
                final rect = Rect.fromLTRB(
                  textBlock.boundingBox.left * scaleX,
                  textBlock.boundingBox.top * scaleY,
                  textBlock.boundingBox.right * scaleX,
                  textBlock.boundingBox.bottom * scaleY,
                );
                if (rect.contains(details.localPosition)) {
                  widget.onTextBlockTap(textBlock.text);
                  return;
                }
              }
            },
            child: CustomPaint(
              foregroundPainter: TextOverlayPainter(
                imageSize: _imageSize!,
                recognizedText: widget.recognizedText,
              ),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          );
  }
}

class TextOverlayPainter extends CustomPainter {
  final Size imageSize;
  final RecognizedText recognizedText;

  TextOverlayPainter({required this.imageSize, required this.recognizedText});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.lightBlueAccent;

    for (final textBlock in recognizedText.blocks) {
      final rect = Rect.fromLTRB(
        textBlock.boundingBox.left * scaleX,
        textBlock.boundingBox.top * scaleY,
        textBlock.boundingBox.right * scaleX,
        textBlock.boundingBox.bottom * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(TextOverlayPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.recognizedText != recognizedText;
  }
}
