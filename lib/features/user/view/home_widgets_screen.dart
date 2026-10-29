import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_button.dart';
import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:passfin/core/models/home_widget_kind.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen> {
  HomeWidgetKind? _pending;
  HomeWidgetKind? _messageKind;
  String? _message;
  bool _isError = false;

  Future<void> _add(HomeWidgetKind kind) async {
    if (_pending != null) return;
    setState(() {
      _pending = kind;
      _messageKind = kind;
      _message = null;
      _isError = false;
    });
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (!mounted) return;
      if (supported == true) {
        await HomeWidget.requestPinWidget(androidName: kind.receiver);
        if (!mounted) return;
        _message = 'Confirme a inclusão de “${kind.title}” na tela do Android.';
      } else {
        _message =
            'Para adicionar, toque e segure um espaço vazio na tela '
            'inicial do celular e escolha Widgets → PassFin.';
      }
    } catch (_) {
      if (!mounted) return;
      _isError = true;
      _message =
          'Não foi possível abrir a seleção. Tente novamente ou '
          'adicione em Widgets → PassFin na tela inicial do celular.';
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      maxContentWidth: 640,
      appBar: AppBar(title: const Text('Widgets do celular')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Seu resumo, sempre por perto',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Os widgets acompanham a cor e o modo de exibição do aplicativo. '
            'Os valores ficam ocultos até você tocar no olho.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tamanhos sugeridos. Para ajustar, toque e segure o widget na tela '
            'inicial. As opções dependem do seu celular.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final kind in HomeWidgetKind.values) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(kind.title, style: theme.textTheme.titleSmall),
                      Text(
                        kind.size,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(kind.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: ValueKey('add-widget-${kind.name}'),
                    label: 'Adicionar',
                    variant: AppButtonVariant.outline,
                    isFullWidth: true,
                    isLoading: _pending == kind,
                    onPressed: _pending == null ? () => _add(kind) : null,
                  ),
                  if (_message != null && _messageKind == kind) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _isError
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
