import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/view/widgets/saved_logos_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:provider/provider.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _photoPath;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _repNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final viewModel = Provider.of<SupplierViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    await viewModel.addSupplier(
      userId: userId,
      name: _nameController.text,
      representativeName:
          _repNameController.text.isNotEmpty ? _repNameController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber:
          _phoneController.text.isNotEmpty ? _phoneController.text : null,
      photoPath: _photoPath,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  void _selectSavedLogo() async {
    final selectedLogo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const SavedLogosScreen(isForSuppliers: true),
      ),
    );

    if (selectedLogo != null) {
      setState(() {
        _photoPath = selectedLogo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Fornecedor')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: LogoPicker(
                  initialImagePath: _photoPath,
                  onImageSelected: (path) {
                    setState(() {
                      _photoPath = path;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _selectSavedLogo,
                    icon: const Icon(Icons.collections_bookmark_outlined,
                        size: 18),
                    label: const Text('Escolher Salva'),
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _photoPath = null;
                        });
                      },
                      icon: const Icon(Icons.no_photography_outlined, size: 18),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nome Fornecedor/Loja *'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repNameController,
                decoration:
                    const InputDecoration(labelText: 'Nome Representante'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration:
                    const InputDecoration(labelText: 'Telefone (WhatsApp)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2.0))
                    : const Text('Salvar Fornecedor'),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
