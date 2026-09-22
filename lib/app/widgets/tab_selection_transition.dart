import 'package:flutter/material.dart';
import 'package:key_budget/app/utils/app_animations.dart';

class TabSelectionTransition extends StatefulWidget {
  final Widget child;
  final int revision;
  final bool enabled;

  const TabSelectionTransition({
    super.key,
    required this.child,
    required this.revision,
    this.enabled = true,
  });

  @override
  State<TabSelectionTransition> createState() => TabSelectionTransitionState();
}

class TabSelectionTransitionState extends State<TabSelectionTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.transition,
      value: 1.0,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curve,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(covariant TabSelectionTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (AppAnimations.isReducedMotion(context) || !widget.enabled) {
      _controller.value = 1.0;
      return;
    }

    if (widget.revision != oldWidget.revision) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.isReducedMotion(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppAnimations.isReducedMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
