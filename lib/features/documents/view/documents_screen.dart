import 'package:passfin/core/design_system/widgets/app_skeleton_tile.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:passfin/app/utils/app_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:passfin/app/widgets/animated_item_sliver.dart';
import 'package:passfin/app/widgets/empty_state_widget.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_search_field.dart';
import 'package:passfin/core/design_system/widgets/app_feedback_panel.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/documents/view/add_document_screen.dart';
import 'package:passfin/features/documents/viewmodel/document_viewmodel.dart';

import '../widgets/document_list_tile.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = ref.read(authViewModelProvider);
      if (authViewModel.currentUser != null) {
        final documentViewModel = ref.read(documentViewModelProvider);
        documentViewModel.listenToDocuments(authViewModel.currentUser!.id);
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
      await ref
          .read(documentViewModelProvider)
          .forceRefresh(authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(documentViewModelProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            viewModel.setSearchQuery('');
          });
        }
      },
      child: AppPageScaffold(
        appBar: AppBar(
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      viewModel.setSearchQuery('');
                    });
                  },
                )
              : null,
          title: AnimatedSwitcher(
            duration: AppAnimations.durationFor(
              context,
              const Duration(milliseconds: 300),
            ),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isSearching
                ? AppSearchField(
                    controller: _searchController,
                    hint: 'Buscar documentos...',
                    onChanged: viewModel.setSearchQuery,
                    onClear: () {
                      _searchController.clear();
                      viewModel.setSearchQuery('');
                    },
                  )
                : const Text('Documentos', key: ValueKey('titleText')),
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: ResponsiveCenter(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  if (viewModel.isLoading)
                    const DocumentsListSkeleton()
                  else if (viewModel.errorMessage != null &&
                      !viewModel.hasDocuments)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppFeedbackPanel(
                        title: 'Falha ao carregar documentos',
                        message: 'Confira sua conexão e tente novamente.',
                        type: AppFeedbackType.error,
                        actionLabel: 'Tentar novamente',
                        onAction: () {
                          final user = ref
                              .read(authViewModelProvider)
                              .currentUser;
                          if (user != null) {
                            viewModel.retryListenToDocuments(user.id);
                          }
                        },
                      ),
                    )
                  else if (viewModel.currentDisplayItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyStateWidget(
                          icon: viewModel.searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.folder_off_outlined,
                          message: viewModel.searchQuery.isNotEmpty
                              ? 'Nenhum documento encontrado para a busca.'
                              : 'Nenhum documento cadastrado.',
                          buttonText: viewModel.searchQuery.isNotEmpty
                              ? 'Limpar busca'
                              : 'Adicionar documento',
                          onButtonPressed: () {
                            if (viewModel.searchQuery.isNotEmpty) {
                              _searchController.clear();
                              viewModel.setSearchQuery('');
                            } else {
                              NavigationUtils.push(
                                context,
                                const AddDocumentScreen(),
                              );
                            }
                          },
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        96.0,
                      ),
                      sliver: AnimatedItemSliver(
                        items: viewModel.currentDisplayItems,
                        identity: (doc) => doc.id!,
                        itemBuilder: (context, doc) {
                          return DocumentListTile(
                            key: ValueKey(doc.id),
                            doc: doc,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              NavigationUtils.push(context, const AddDocumentScreen()),
          label: const Text('Novo Documento'),
          icon: const Icon(Icons.add),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXXL,
          ),
        ),
      ),
    );
  }
}

class DocumentsListSkeleton extends StatelessWidget {
  const DocumentsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    sliver: SliverList.builder(
      itemCount: 8,
      itemBuilder: (context, index) => const AppSkeletonTile(),
    ),
  );
}
