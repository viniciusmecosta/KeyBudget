import 'package:flutter/material.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _highlightController.forward();
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart highlight animation if the child content changes
    if (widget.child.key != oldWidget.child.key) {
      _highlightController.reset();
      _highlightController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _highlightAnimation = ColorTween(
      begin: theme.colorScheme.primary.withOpacity(0.2),
      end: theme.colorScheme.surface.withOpacity(0.0),
    ).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: _highlightAnimation.value,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
      child: FadeTransition(
        opacity: widget.animation,
        child: SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: widget.animation,
            curve: Curves.easeOut,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
