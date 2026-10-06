import 'package:flutter/material.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';

class AnimatedItemSliver<T> extends StatefulWidget {
  final List<T> items;
  final Object Function(T item) identity;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const AnimatedItemSliver({
    super.key,
    required this.items,
    required this.identity,
    required this.itemBuilder,
  });

  @override
  State<AnimatedItemSliver<T>> createState() => _AnimatedItemSliverState<T>();
}

class _AnimatedItemSliverState<T> extends State<AnimatedItemSliver<T>> {
  final _listKey = GlobalKey<SliverAnimatedListState>();
  late List<T> _visibleItems;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _visibleItems = List<T>.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant AnimatedItemSliver<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted) _syncItems();
    });
  }

  void _syncItems() {
    final target = widget.items;
    final list = _listKey.currentState;
    if (list == null) {
      setState(() => _visibleItems = List<T>.of(target));
      return;
    }
    final targetIds = target.map(widget.identity).toSet();
    final duration = AppAnimations.durationFor(
      context,
      AppAnimations.transition,
    );

    void removeAt(int index) {
      final removed = _visibleItems.removeAt(index);
      list.removeItem(
        index,
        (context, animation) => IgnorePointer(
          child: AnimatedListItem(
            animation: animation,
            child: widget.itemBuilder(context, removed),
          ),
        ),
        duration: duration,
      );
    }

    for (var index = _visibleItems.length - 1; index >= 0; index--) {
      if (!targetIds.contains(widget.identity(_visibleItems[index]))) {
        removeAt(index);
      }
    }

    for (var index = 0; index < target.length; index++) {
      final item = target[index];
      final itemId = widget.identity(item);
      if (index < _visibleItems.length &&
          widget.identity(_visibleItems[index]) == itemId) {
        _visibleItems[index] = item;
        continue;
      }
      final previousIndex = _visibleItems.indexWhere(
        (visible) => widget.identity(visible) == itemId,
      );
      if (previousIndex >= 0) removeAt(previousIndex);
      _visibleItems.insert(index, item);
      list.insertItem(index, duration: duration);
    }

    while (_visibleItems.length > target.length) {
      removeAt(_visibleItems.length - 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => SliverAnimatedList(
    key: _listKey,
    initialItemCount: _visibleItems.length,
    itemBuilder: (context, index, animation) {
      if (index >= _visibleItems.length) return const SizedBox.shrink();
      return AnimatedListItem(
        animation: animation,
        child: widget.itemBuilder(context, _visibleItems[index]),
      );
    },
  );
}
