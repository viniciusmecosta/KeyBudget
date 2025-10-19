import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WidgetToImage {
  static Future<Uint8List?> captureWidget(
    BuildContext context,
    Widget widget, {
    Duration? wait,
    double pixelRatio = 3.0,
  }) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    final ui.FlutterView view =
        View.maybeOf(context) ?? ui.PlatformDispatcher.instance.views.first;
    Size logicalSize = view.physicalSize / view.devicePixelRatio;

    final RenderView renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: pixelRatio,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);

    if (wait != null) {
      await Future.delayed(wait);
    }

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image? image;
    try {
      image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget to image: $e');
      return null;
    } finally {
      image?.dispose();
    }
  }

  static Future<Uint8List?> captureWidgetFromProvider(
      BuildContext context, Widget widget,
      {Duration? wait}) async {
    final GlobalKey key = GlobalKey();
    final completer = Completer<Uint8List?>();

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height,
        left: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: key,
            child: widget,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (wait != null) {
        await Future.delayed(wait);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        RenderRepaintBoundary? boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null && !boundary.debugNeedsPaint) {
          ui.Image image = await boundary.toImage(pixelRatio: 3.0);
          ByteData? byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          completer.complete(byteData?.buffer.asUint8List());
        } else {
          debugPrint(
              'Error capturing widget: Boundary needs paint or is null.');
          await Future.delayed(const Duration(milliseconds: 500));
          if (boundary != null && !boundary.debugNeedsPaint) {
            ui.Image image = await boundary.toImage(pixelRatio: 3.0);
            ByteData? byteData =
                await image.toByteData(format: ui.ImageByteFormat.png);
            completer.complete(byteData?.buffer.asUint8List());
          } else {
            debugPrint(
                'Error capturing widget: Boundary still needs paint or is null after retry.');
            completer.complete(null);
          }
        }
      } catch (e) {
        debugPrint('Error capturing widget with provider: $e');
        completer.complete(null);
      } finally {
        overlayEntry.remove();
      }
    });

    return completer.future;
  }
}
