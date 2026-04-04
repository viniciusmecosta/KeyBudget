import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/view/add_document_screen.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/document_list_tile.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        final documentViewModel =
            Provider.of<DocumentViewModel>(context, listen: false);
        documentViewModel.setListKey(_listKey);
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
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      await Provider.of<DocumentViewModel>(context, listen: false)
          .forceRefresh(authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();
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
      child: Scaffold(
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
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isSearching
                ? Container(
                    key: const ValueKey('searchBox'),
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Buscar documentos...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  viewModel.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => viewModel.setSearchQuery(val),
                    ),
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
          child: AppAnimations.fadeInFromBottom(
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  if (viewModel.isLoading)
                    const DocumentsListSkeleton()
                  else if (viewModel.currentDisplayItems.isEmpty)
                    const SliverFillRemaining(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: EmptyStateWidget(
                          icon: Icons.folder_off_outlined,
                          message: 'Nenhum documento encontrado.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.defaultPadding,
                          AppTheme.spaceL,
                          AppTheme.defaultPadding,
                          96.0),
                      sliver: SliverAnimatedList(
                        key: _listKey,
                        initialItemCount: viewModel.currentDisplayItems.length,
                        itemBuilder: (context, index, animation) {
                          if (index >= viewModel.currentDisplayItems.length) {
                            return const SizedBox.shrink();
                          }
                          final doc = viewModel.currentDisplayItems[index];
                          return AnimatedListItem(
                            animation: animation,
                            child: DocumentListTile(
                                key: ValueKey(doc.id), doc: doc),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton:
            AppAnimations.scaleIn(FloatingActionButton.extended(
          onPressed: () =>
              NavigationUtils.push(context, const AddDocumentScreen()),
          label: const Text('Novo Documento'),
          icon: const Icon(Icons.add),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          ),
        )),
      ),
    );
  }
}

class DocumentsListSkeleton extends StatelessWidget {
  const DocumentsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerHighlightColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppTheme.defaultPadding,
          AppTheme.spaceL, AppTheme.defaultPadding, 96.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                duration: 1500.ms,
                color: shimmerHighlightColor,
              ),
          childCount: 8,
        ),
      ),
    );
  }
}