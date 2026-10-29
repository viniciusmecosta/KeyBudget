import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/navigation/app_destination.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/services/snackbar_service.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';

class NavigationCustomizationScreen extends ConsumerStatefulWidget {
  const NavigationCustomizationScreen({super.key});

  @override
  ConsumerState<NavigationCustomizationScreen> createState() =>
      _NavigationCustomizationScreenState();
}

class _NavigationCustomizationScreenState
    extends ConsumerState<NavigationCustomizationScreen> {
  late List<AppDestination> _order;
  late Set<String> _hidden;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).currentUser;
    final enabled = user?.enableSuppliers ?? false;
    final savedOrder = user?.navigationOrder ?? const <String>[];
    _order = AppDestination.values
        .where(
          (destination) => destination != AppDestination.suppliers || enabled,
        )
        .toList();
    final positions = {
      for (var index = 0; index < savedOrder.length; index++)
        savedOrder[index]: index,
    };
    _order.sort((a, b) {
      final aIndex =
          positions[a.id] ??
          savedOrder.length + AppDestination.values.indexOf(a);
      final bIndex =
          positions[b.id] ??
          savedOrder.length + AppDestination.values.indexOf(b);
      return aIndex.compareTo(bIndex);
    });
    _hidden = {...?user?.hiddenNavigationDestinations};
  }

  Future<void> _save() async {
    final user = ref.read(authViewModelProvider).currentUser;
    if (user == null || _saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(authViewModelProvider)
        .updateUser(
          name: user.name,
          hiddenNavigationDestinations: _hidden.toList(),
          navigationOrder: [
            ..._order.map((destination) => destination.id),
            if (!(_order.contains(AppDestination.suppliers)))
              AppDestination.suppliers.id,
          ],
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.profileUpdated) {
      Navigator.of(context).pop();
      return;
    }
    SnackbarService.showError(
      context,
      result.errorMessage ??
          'Não foi possível salvar as abas. Tente novamente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    return AppPageScaffold(
      appBar: AppBar(title: const Text('Personalizar abas')),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arraste para ordenar. Desative o que não usa.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _order.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _order.removeAt(oldIndex);
                      _order.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final destination = _order[index];
                    final fixed =
                        destination == AppDestination.expenses ||
                        destination == AppDestination.credentials;
                    return AppCard(
                      padding: EdgeInsets.zero,
                      key: ValueKey(destination.id),
                      child: SwitchListTile(
                        secondary: Icon(destination.icon),
                        title: Text(destination.label),
                        subtitle: fixed
                            ? const Text('Sempre disponível')
                            : null,
                        value: fixed || !_hidden.contains(destination.id),
                        onChanged: fixed
                            ? null
                            : (enabled) => setState(() {
                                if (enabled) {
                                  _hidden.remove(destination.id);
                                } else {
                                  _hidden.add(destination.id);
                                }
                              }),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: user == null || _saving ? null : _save,
                  child: Text(_saving ? 'Salvando...' : 'Salvar abas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
