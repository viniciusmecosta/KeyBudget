import 'package:flutter/material.dart';

class AppPageScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final double maxContentWidth;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  const AppPageScaffold({
    super.key,
    this.appBar,
    this.body,
    this.maxContentWidth = 1200,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: 0.10),
              backgroundColor ?? theme.scaffoldBackgroundColor,
            ),
            backgroundColor ?? theme.scaffoldBackgroundColor,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body == null
            ? null
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SizedBox.expand(child: body),
                ),
              ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
