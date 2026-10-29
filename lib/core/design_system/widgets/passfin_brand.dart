import 'package:flutter/material.dart';

/// Density-aware exports of the SVG masters in assets/brand.
/// Brand colors stay stable when the user customizes the interface accent.
class PassFinBrand extends StatelessWidget {
  const PassFinBrand({
    super.key,
    this.showName = false,
    this.width = 96,
    this.semanticLabel = 'PassFin',
  });

  final bool showName;
  final double width;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).brightness == Brightness.dark
        ? 'dark'
        : 'light';
    final kind = showName ? 'signature' : 'symbol';
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          'assets/brand/passfin-$kind-$variant.png',
          width: width,
          height: showName ? width * 256 / 1000 : width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
