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
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;
  late AnimationController _editController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late Animation<Color?> _shadowColorAnimation;
  late Animation<double> _shadowBlurAnimation;
  late Animation<Offset> _shadowOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _editController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _shadowColorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(
              begin: Colors.black.withOpacity(0),
              end: Colors.black.withOpacity(0.15)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: Colors.black.withOpacity(0.15),
              end: Colors.black.withOpacity(0.15)),
          weight: 2),
      TweenSequenceItem(
          tween: ColorTween(
              begin: Colors.black.withOpacity(0.15),
              end: Colors.black.withOpacity(0)),
          weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _shadowBlurAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 15.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 15.0, end: 15.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 15.0, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _shadowOffsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0, 8)), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0, 8), end: const Offset(0, 8)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0, 8), end: Offset.zero), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _highlightController.forward();
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _editController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _highlightController.reset();
      _highlightController.forward();
      _editController.reset();
      _editController.forward();
      _shakeController.reset();
      _shakeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _highlightAnimation = ColorTween(
      begin: theme.colorScheme.primary.withAlpha(51),
      end: theme.colorScheme.surface.withAlpha(0),
    ).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(
            parent: _editController,
            curve: Curves.easeOut,
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_highlightAnimation, _shakeController]),
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: _highlightAnimation.value,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _shadowColorAnimation.value!,
                    blurRadius: _shadowBlurAnimation.value,
                    offset: _shadowOffsetAnimation.value,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FadeTransition(
              opacity: widget.animation,
              child: SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: widget.animation,
                  curve: Curves.easeOut,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
