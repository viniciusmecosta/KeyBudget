import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/design_system/widgets/app_search_field.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/view/add_supplier_screen.dart';
import 'package:key_budget/features/suppliers/view/supplier_detail_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';

import '../widgets/supplier_list_tile.dart';
import '../widgets/supplier_preview_panel.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = ref.read(authViewModelProvider);
      if (authViewModel.currentUser != null) {
        ref
            .read(supplierViewModelProvider)
            .listenToSuppliers(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final authViewModel = ref.read(authViewModelProvider);
    if (mounted && authViewModel.currentUser != null) {
      ref
          .read(supplierViewModelProvider)
          .listenToSuppliers(authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(supplierViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                  ref.read(supplierViewModelProvider).setSearchQuery('');
                },
              )
            : null,
        title: _isSearching
            ? AppSearchField(
                controller: _searchController,
                hint: 'Buscar fornecedores...',
                onChanged: ref.read(supplierViewModelProvider).setSearchQuery,
                onClear: () {
                  _searchController.clear();
                  ref.read(supplierViewModelProvider).setSearchQuery('');
                },
              )
            : const Text('Fornecedores'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(supplierViewModelProvider).setSearchQuery('');
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: AppAnimations.fadeInFromBottom(
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            strokeWidth: 2.5,
            child: ResponsiveCenter(
              maxWidth: 1200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSplit =
                      constraints.maxWidth >= 850 &&
                      viewModel.filteredSuppliers.isNotEmpty;
                  final selectedSupplier = showSplit
                      ? viewModel.filteredSuppliers.firstWhere(
                          (supplier) => supplier.id == _selectedSupplierId,
                          orElse: () => viewModel.filteredSuppliers.first,
                        )
                      : null;
                  return Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            if (viewModel.isLoading)
                              const SuppliersSkeleton()
                            else if (viewModel.hasLoadError &&
                                viewModel.allSuppliers.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AppFeedbackPanel(
                                  title: viewModel.isOffline
                                      ? 'Sem conexão'
                                      : 'Falha ao carregar fornecedores',
                                  message: viewModel.isOffline
                                      ? 'Confira sua conexão e tente novamente.'
                                      : 'Não foi possível carregar seus fornecedores agora.',
                                  type: AppFeedbackType.error,
                                  actionLabel: 'Tentar novamente',
                                  onAction: () {
                                    final user = ref
                                        .read(authViewModelProvider)
                                        .currentUser;
                                    if (user != null) {
                                      viewModel.retryListenToSuppliers(user.id);
                                    }
                                  },
                                ),
                              )
                            else if (viewModel.allSuppliers.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: EmptyStateWidget(
                                  icon: Icons.storefront_outlined,
                                  message: 'Nenhum fornecedor cadastrado.',
                                  buttonText: 'Adicionar Fornecedor',
                                  onButtonPressed: () => NavigationUtils.push(
                                    context,
                                    const AddSupplierScreen(),
                                  ),
                                ),
                              )
                            else if (viewModel.filteredSuppliers.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: EmptyStateWidget(
                                  icon: Icons.search_off_rounded,
                                  message:
                                      'Nenhum fornecedor encontrado para a busca.',
                                  buttonText: 'Limpar busca',
                                  onButtonPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    viewModel.setSearchQuery('');
                                  },
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.all(
                                  AppTheme.defaultPadding,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final supplier =
                                          viewModel.filteredSuppliers[index];
                                      return SupplierListTile(
                                        supplier: supplier,
                                        selected:
                                            showSplit &&
                                            selectedSupplier?.id == supplier.id,
                                        onTap: showSplit
                                            ? () => setState(
                                                () => _selectedSupplierId =
                                                    supplier.id,
                                              )
                                            : null,
                                      );
                                    },
                                    childCount:
                                        viewModel.filteredSuppliers.length,
                                  ),
                                ),
                              ),
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 80),
                            ),
                          ],
                        ),
                      ),
                      if (selectedSupplier != null) ...[
                        VerticalDivider(
                          width: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Expanded(
                          flex: 4,
                          child: SupplierPreviewPanel(
                            key: ValueKey(selectedSupplier.id),
                            supplier: selectedSupplier,
                            onOpen: () => NavigationUtils.push(
                              context,
                              SupplierDetailScreen(supplier: selectedSupplier),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          context: context,
        ),
      ),
      floatingActionButton: AppAnimations.scaleIn(
        FloatingActionButton.extended(
          heroTag: 'fab_suppliers',
          onPressed: () {
            HapticFeedback.lightImpact();
            NavigationUtils.push(context, const AddSupplierScreen());
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text("Novo Fornecedor"),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusL),
          elevation: 0,
        ),

        context: context,
      ),
    );
  }
}

class SuppliersSkeleton extends ConsumerWidget {
  const SuppliersSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: shimmerColor);
        }, childCount: 8),
      ),
    );
  }
}
