import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum OcrTargetField { amount, date, motivation, location, none }

class OcrDetailedViewerScreen extends StatefulWidget {
  final String imagePath;
  final RecognizedText recognizedText;
  final Map<OcrTargetField, String> initialAssignments;

  const OcrDetailedViewerScreen({
    super.key,
    required this.imagePath,
    required this.recognizedText,
    required this.initialAssignments,
  });

  @override
  State<OcrDetailedViewerScreen> createState() =>
      _OcrDetailedViewerScreenState();
}

class _OcrDetailedViewerScreenState extends State<OcrDetailedViewerScreen> {
  Size? _imageSize;
  final TransformationController _transformationController =
      TransformationController();
  late Map<OcrTargetField, String?> _currentAssignments;
  TextBlock? _tappedBlock;
  Offset? _tapPosition;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentAssignments = Map.from(widget.initialAssignments);
    for (var field in OcrTargetField.values) {
      if (field != OcrTargetField.none &&
          !_currentAssignments.containsKey(field)) {
        _currentAssignments[field] = null;
      }
    }
    _getImageSize();
  }

  Future<void> _getImageSize() async {
    final image = File(widget.imagePath);
    final codec = await ui.instantiateImageCodec(image.readAsBytesSync());
    final frameInfo = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageSize = Size(frameInfo.image.width.toDouble(),
            frameInfo.image.height.toDouble());
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_imageSize == null) return;
    final RenderBox? paintBox =
        _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (paintBox == null) return;

    final Offset localTouchPosition =
        paintBox.globalToLocal(details.globalPosition);

    final Size paintCanvasSize = paintBox.size;

    final double imgAspectRatio = _imageSize!.width / _imageSize!.height;
    final double canvasAspectRatio =
        paintCanvasSize.width / paintCanvasSize.height;
    double baseScale;
    Offset originOffset = Offset.zero;

    if (imgAspectRatio > canvasAspectRatio) {
      baseScale = paintCanvasSize.width / _imageSize!.width;
      final scaledHeight = _imageSize!.height * baseScale;
      originOffset = Offset(0, (paintCanvasSize.height - scaledHeight) / 2);
    } else {
      baseScale = paintCanvasSize.height / _imageSize!.height;
      final scaledWidth = _imageSize!.width * baseScale;
      originOffset = Offset((paintCanvasSize.width - scaledWidth) / 2, 0);
    }

    final Matrix4 matrix = _transformationController.value;
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final Offset transformedTouchPosition =
        MatrixUtils.transformPoint(inverseMatrix, localTouchPosition);

    final Offset tapPositionOnOriginalImage = Offset(
      (transformedTouchPosition.dx - originOffset.dx) / baseScale,
      (transformedTouchPosition.dy - originOffset.dy) / baseScale,
    );

    for (final textBlock in widget.recognizedText.blocks) {
      if (textBlock.boundingBox.contains(tapPositionOnOriginalImage)) {
        setState(() {
          _tappedBlock = textBlock;
          _tapPosition = details.globalPosition;
        });
        _showAssignmentMenu(context);
        return;
      }
    }

    setState(() {
      _tappedBlock = null;
      _tapPosition = null;
    });
  }

  void _showAssignmentMenu(BuildContext context) {
    if (_tappedBlock == null || _tapPosition == null) return;

    final tappedText = _tappedBlock!.text;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    OcrTargetField? currentlyAssignedTo;
    _currentAssignments.forEach((field, text) {
      if (text == tappedText) {
        currentlyAssignedTo = field;
      }
    });

    List<PopupMenuEntry<OcrTargetField>> menuItems = [];

    if (currentlyAssignedTo != OcrTargetField.amount) {
      menuItems.add(const PopupMenuItem(
          value: OcrTargetField.amount, child: Text('Usar como Valor')));
    }
    if (currentlyAssignedTo != OcrTargetField.date) {
      menuItems.add(const PopupMenuItem(
          value: OcrTargetField.date, child: Text('Usar como Data')));
    }
    if (currentlyAssignedTo != OcrTargetField.motivation) {
      menuItems.add(const PopupMenuItem(
          value: OcrTargetField.motivation,
          child: Text('Usar como Motivação')));
    }
    if (currentlyAssignedTo != OcrTargetField.location) {
      menuItems.add(const PopupMenuItem(
          value: OcrTargetField.location, child: Text('Usar como Local')));
    }

    if (currentlyAssignedTo != null) {
      menuItems.add(const PopupMenuDivider());
      menuItems.add(PopupMenuItem(
          value: OcrTargetField.none,
          child: Text('Desmarcar',
              style: TextStyle(color: Theme.of(context).colorScheme.error))));
    }

    showMenu<OcrTargetField>(
      context: context,
      position: RelativeRect.fromRect(
          _tapPosition! & const Size(40, 40), Offset.zero & overlay.size),
      items: menuItems,
    ).then((OcrTargetField? selectedField) {
      if (selectedField != null) {
        setState(() {
          if (selectedField == OcrTargetField.none) {
            if (currentlyAssignedTo != null) {
              _currentAssignments[currentlyAssignedTo!] = null;
            }
          } else {
            _currentAssignments.forEach((field, text) {
              if (text == tappedText && field != selectedField) {
                _currentAssignments[field] = null;
              }
            });
            _currentAssignments[selectedField] = tappedText;
          }
        });
      }
      setState(() {
        _tappedBlock = null;
        _tapPosition = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atribuir Texto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Confirmar Atribuições',
            onPressed: () {
              final Map<OcrTargetField, String> finalAssignments = {};
              _currentAssignments.forEach((key, value) {
                if (value != null) {
                  finalAssignments[key] = value;
                }
              });
              Navigator.of(context).pop(finalAssignments);
            },
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: _imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: _handleTapUp,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.1,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _imageSize!.width / _imageSize!.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                            CustomPaint(
                              key: _paintKey,
                              painter: TextOverlayPainter(
                                imageSize: _imageSize!,
                                recognizedText: widget.recognizedText,
                                currentAssignments: _currentAssignments,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TextOverlayPainter extends CustomPainter {
  final Size imageSize;
  final RecognizedText recognizedText;
  final Map<OcrTargetField, String?> currentAssignments;

  static const Color amountColor = Colors.redAccent;
  static const Color dateColor = Colors.purpleAccent;
  static const Color motivationColor = Colors.blueAccent;
  static const Color locationColor = Colors.greenAccent;
  static final Color otherColor = Colors.grey.shade400;

  static const double assignedFillOpacity = 0.35;
  static const double assignedStrokeWidth = 2.5;
  static const double otherStrokeWidth = 1.5;

  TextOverlayPainter({
    required this.imageSize,
    required this.recognizedText,
    required this.currentAssignments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    for (final textBlock in recognizedText.blocks) {
      final text = textBlock.text;
      Color color = otherColor;
      bool isAssigned = false;
      double strokeWidth = otherStrokeWidth;

      currentAssignments.forEach((field, assignedText) {
        if (assignedText == text) {
          isAssigned = true;
          strokeWidth = assignedStrokeWidth;
          switch (field) {
            case OcrTargetField.amount:
              color = amountColor;
              break;
            case OcrTargetField.date:
              color = dateColor;
              break;
            case OcrTargetField.motivation:
              color = motivationColor;
              break;
            case OcrTargetField.location:
              color = locationColor;
              break;
            case OcrTargetField.none:
              break;
          }
        }
      });

      final rect = Rect.fromLTRB(
        textBlock.boundingBox.left * scaleX,
        textBlock.boundingBox.top * scaleY,
        textBlock.boundingBox.right * scaleX,
        textBlock.boundingBox.bottom * scaleY,
      );

      if (isAssigned) {
        final Paint fillPaint = Paint()
          ..color = color.withAlpha((255 * assignedFillOpacity).round())
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fillPaint);
      }

      final Paint borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(TextOverlayPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.recognizedText != recognizedText ||
        oldDelegate.currentAssignments != currentAssignments;
  }
}
