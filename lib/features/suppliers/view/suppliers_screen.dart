import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/view/add_supplier_screen.dart';
import 'package:key_budget/features/suppliers/view/supplier_detail_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _launchWhatsApp(String phone) async {
    final whatsappUrl = "https://wa.me/$phone";
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  void _launchEmail(String email) async {
    final emailUrl = 'mailto:$email';
    final uri = Uri.parse(emailUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o app de e-mail.')),
      );
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
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                padding: const EdgeInsets.all(AppTheme.defaultPadding),
                itemCount: vm.allSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = vm.allSuppliers[index];
                  final photoPath = supplier.photoPath;
                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.15),
                        backgroundImage: photoPath != null && photoPath.isNotEmpty
                            ? MemoryImage(base64Decode(photoPath))
                            : null,
                        child: photoPath == null || photoPath.isEmpty
                            ? Icon(Icons.store_outlined,
                            color: Theme.of(context).colorScheme.tertiary)
                            : null,
                      ),
                      title: Text(supplier.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(supplier.representativeName ?? 'Sem representante'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (supplier.phoneNumber != null && supplier.phoneNumber!.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.message, color: Colors.green.shade600),
                              onPressed: () => _launchWhatsApp(supplier.phoneNumber!),
                            ),
                          if (supplier.email != null && supplier.email!.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.email_outlined, color: Colors.blue.shade600),
                              onPressed: () => _launchEmail(supplier.email!),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SupplierDetailScreen(supplier: supplier),
                          ),
                        );
                      },
                    ),
                  );
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