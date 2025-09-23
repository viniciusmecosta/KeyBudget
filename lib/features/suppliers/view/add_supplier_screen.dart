import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../widgets/supplier_form.dart';

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
    final phoneMaskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

    await viewModel.addSupplier(
      userId: userId,
      name: _nameController.text,
      representativeName:
          _repNameController.text.isNotEmpty ? _repNameController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber: phoneMaskFormatter.unmaskText(_phoneController.text),
      photoPath: _photoPath,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Fornecedor')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: SupplierForm(
                formKey: _formKey,
                nameController: _nameController,
                repNameController: _repNameController,
                emailController: _emailController,
                phoneController: _phoneController,
                notesController: _notesController,
                photoPath: _photoPath,
                onPhotoChanged: (path) {
                  setState(() {
                    _photoPath = path;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
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
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
