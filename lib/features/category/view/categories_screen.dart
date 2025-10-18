import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/add_edit_category_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId =
          Provider.of<AuthViewModel>(context, listen: false).currentUser?.id;
      if (userId != null) {
        Provider.of<CategoryViewModel>(context, listen: false)
            .fetchCategories(userId);
      }
    });
  }

  void _deleteCategory(BuildContext context, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir a categoria "${category.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Excluir'),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final auth = Provider.of<AuthViewModel>(context, listen: false);
              final viewModel =
                  Provider.of<CategoryViewModel>(context, listen: false);
              final navigator = Navigator.of(ctx);
              final scaffoldContext = context;

              final userId = auth.currentUser?.id;
              if (userId == null) {
                navigator.pop();
                return;
              }

              await viewModel.deleteCategory(userId, category.id!);

              if (!scaffoldContext.mounted) return;
              SnackbarService.showSuccess(
                  scaffoldContext, 'Categoria excluída com sucesso!');
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Categorias'),
      ),
      body: Consumer<CategoryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria cadastrada.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            itemCount: viewModel.categories.length,
            itemBuilder: (context, index) {
              final category = viewModel.categories[index];
              return AppAnimations.listFadeIn(
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 0,
                    child: InkWell(
                      onTap: () {
                        NavigationUtils.push(
                            context, AddEditCategoryScreen(category: category));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withAlpha((255 * 0.1).round()),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  category.color.withAlpha((255 * 0.2).round()),
                              child: Icon(category.icon, color: category.color),
                            ),
                            const SizedBox(width: AppTheme.spaceM),
                            Expanded(child: Text(category.name)),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                NavigationUtils.push(context,
                                    AddEditCategoryScreen(category: category));
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () =>
                                  _deleteCategory(context, category),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                index: index,
              );
            },
          );
        },
      ),
      floatingActionButton: AppAnimations.scaleIn(FloatingActionButton(
        heroTag: 'fab_categories',
        onPressed: () {
          NavigationUtils.push(context, const AddEditCategoryScreen());
        },
        child: const Icon(Icons.add),
      )),
    );
  }
}
