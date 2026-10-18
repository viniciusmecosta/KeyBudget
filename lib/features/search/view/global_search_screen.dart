import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/documents/view/document_detail_screen.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/search/domain/global_search_index.dart';
import 'package:key_budget/features/search/repository/search_favorites_repository.dart';
import 'package:key_budget/features/suppliers/view/supplier_detail_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  bool _onlyFavorites = false;
  String? _boundUserId;
  bool _bindingScheduled = false;

  void _bindSources(String userId) {
    if (_boundUserId == userId || _bindingScheduled) return;
    _bindingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindingScheduled = false;
      if (!mounted ||
          ref.read(authViewModelProvider).currentUser?.id != userId) {
        return;
      }
      ref.read(expenseViewModelProvider).listenToExpenses(userId);
      ref.read(credentialViewModelProvider).listenToCredentials(userId);
      ref.read(documentViewModelProvider).listenToDocuments(userId);
      final user = ref.read(authViewModelProvider).currentUser;
      if (user?.enableSuppliers == true &&
          !(user?.hiddenNavigationDestinations.contains('suppliers') ??
              false)) {
        ref.read(supplierViewModelProvider).listenToSuppliers(userId);
      }
      setState(() => _boundUserId = userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(GlobalSearchResult result) {
    final page = switch (result.kind) {
      GlobalSearchKind.expense => ExpenseDetailScreen(
        expense: result.item as Expense,
      ),
      GlobalSearchKind.credential => CredentialDetailScreen(
        credential: result.item as Credential,
      ),
      GlobalSearchKind.document => DocumentDetailScreen(
        document: result.item as Document,
      ),
      GlobalSearchKind.supplier => SupplierDetailScreen(
        supplier: result.item as Supplier,
      ),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _toggleFavorite(
    String userId,
    GlobalSearchResult result,
    bool favorite,
  ) async {
    try {
      await ref
          .read(searchFavoritesRepositoryProvider)
          .setFavorite(userId, result.favoriteId, !favorite);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível atualizar o favorito.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final userId = user?.id;
    if (userId != null) _bindSources(userId);
    final favorites = userId == null
        ? null
        : ref.watch(searchFavoritesProvider(userId));
    final expenses = ref.watch(expenseViewModelProvider);
    final credentials = ref.watch(credentialViewModelProvider);
    final documents = ref.watch(documentViewModelProvider);
    final suppliers = ref.watch(supplierViewModelProvider);
    final query = _searchController.text.trim();
    final results = userId != null && userId == _boundUserId
        ? GlobalSearchIndex.search(
            query: query,
            expenses: expenses.allExpenses,
            credentials: credentials.allCredentials,
            documents: documents.allDocuments,
            suppliers: suppliers.allSuppliers,
            includeDocuments:
                !(user?.hiddenNavigationDestinations.contains('documents') ??
                    false),
            includeSuppliers:
                user?.enableSuppliers == true &&
                !(user?.hiddenNavigationDestinations.contains('suppliers') ??
                    false),
          )
        : <GlobalSearchResult>[];
    final favoriteIds = favorites?.value ?? const <String>{};
    final visible = results
        .where((result) {
          if (query.isEmpty || _onlyFavorites) {
            return favoriteIds.contains(result.favoriteId);
          }
          return true;
        })
        .take(100)
        .toList();

    return AppPageScaffold(
      appBar: AppBar(title: const Text('Buscar no aplicativo')),
      body: ResponsiveCenter(
        maxWidth: 760,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar lançamentos, credenciais e mais',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () => setState(_searchController.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('Somente favoritos'),
                  selected: _onlyFavorites,
                  onSelected: (value) => setState(() => _onlyFavorites = value),
                ),
              ),
              Expanded(
                child: userId == null
                    ? const AppFeedbackPanel(
                        title: 'Entre na sua conta',
                        message: 'Faça login para buscar seus dados.',
                      )
                    : favorites?.hasError == true
                    ? AppFeedbackPanel(
                        title: 'Não foi possível carregar os favoritos',
                        message: 'Confira a conexão e tente novamente.',
                        type: AppFeedbackType.error,
                        actionLabel: 'Tentar novamente',
                        onAction: () =>
                            ref.invalidate(searchFavoritesProvider(userId)),
                      )
                    : visible.isEmpty
                    ? AppFeedbackPanel(
                        title: query.isEmpty
                            ? 'Nenhum favorito'
                            : 'Nada encontrado',
                        message: query.isEmpty
                            ? 'Pesquise e toque na estrela para guardar um acesso rápido.'
                            : 'Tente outro nome ou descrição.',
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final result = visible[index];
                          final isFavorite = favoriteIds.contains(
                            result.favoriteId,
                          );
                          return AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: Icon(switch (result.kind) {
                                GlobalSearchKind.expense =>
                                  Icons.receipt_long_outlined,
                                GlobalSearchKind.credential =>
                                  Icons.key_outlined,
                                GlobalSearchKind.document =>
                                  Icons.description_outlined,
                                GlobalSearchKind.supplier =>
                                  Icons.storefront_outlined,
                              }),
                              title: Text(
                                result.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                result.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: isFavorite
                                    ? 'Remover dos favoritos'
                                    : 'Adicionar aos favoritos',
                                icon: Icon(
                                  isFavorite ? Icons.star : Icons.star_border,
                                ),
                                onPressed: () =>
                                    _toggleFavorite(userId, result, isFavorite),
                              ),
                              onTap: () => _open(result),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
