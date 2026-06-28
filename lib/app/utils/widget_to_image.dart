import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // We use the offline renderer but wrap it in the required context providers
    // to avoid Impeller culling the widget on the live overlay.
    return captureWidget(
      context,
      UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: Theme(
          data: Theme.of(context),
          child: MediaQuery(
            data: MediaQuery.of(context),
            child: Material(
              type: MaterialType.transparency,
              child: widget,
            ),
          ),
        ),
      ),
      wait: wait,
    );
  }
}
