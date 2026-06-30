import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/constants/app_icons.dart';

class IconPickerWidget extends ConsumerStatefulWidget {
  final Color? selectedColor;

  const IconPickerWidget({super.key, this.selectedColor});

  @override
  ConsumerState<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends ConsumerState<IconPickerWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.selectedColor ?? theme.colorScheme.primary;
    final allIcons = AppIcons.all;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Text('Selecione um Ícone', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: allIcons.length,
                  itemBuilder: (context, index) {
                    final icon = allIcons[index];
                    return IconButton(
                      icon: Icon(
                        icon,
                        size: 32,
                        color: baseColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(icon),
                      style: IconButton.styleFrom(
                        backgroundColor: baseColor.withAlpha(50),
                        shape: const CircleBorder(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
