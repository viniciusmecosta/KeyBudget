import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/view/add_supplier_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/supplier_list_tile.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<SupplierViewModel>(context, listen: false)
            .listenToSuppliers(authViewModel.currentUser!.id);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      Provider.of<SupplierViewModel>(context, listen: false)
          .listenToSuppliers(authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Consumer<SupplierViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.allSuppliers.isEmpty) {
                return LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: EmptyStateWidget(
                        icon: Icons.store_mall_directory_outlined,
                        message: 'Nenhum fornecedor encontrado.',
                        buttonText: 'Adicionar Fornecedor',
                        onButtonPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AddSupplierScreen())),
                      ),
                    ),
                  );
                });
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppTheme.defaultPadding,
                    AppTheme.defaultPadding, AppTheme.defaultPadding, 80),
                itemCount: vm.allSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = vm.allSuppliers[index];
                  return SupplierListTile(supplier: supplier);
                },
              );
            },
          ),
        ).animate().fadeIn(duration: 250.ms),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_suppliers',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddSupplierScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Novo Fornecedor"),
      ).animate().scale(duration: 250.ms),
    );
  }
}
