import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../widgets/supplier_form.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _repNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  String? _photoPath;
  bool _isEditing = false;
  bool _isSaving = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier.name);
    _repNameController =
        TextEditingController(text: widget.supplier.representativeName);
    _emailController = TextEditingController(text: widget.supplier.email);
    _phoneController = TextEditingController(
        text: _phoneMaskFormatter.maskText(widget.supplier.phoneNumber ?? ''));
    _notesController = TextEditingController(text: widget.supplier.notes);
    _photoPath = widget.supplier.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    await Provider.of<SupplierViewModel>(context, listen: false).updateSupplier(
      userId: userId,
      originalSupplier: widget.supplier,
      name: _nameController.text,
      representativeName:
          _repNameController.text.isNotEmpty ? _repNameController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber: _phoneMaskFormatter.unmaskText(_phoneController.text),
      photoPath: _photoPath,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    Navigator.of(context).pop();
  }

  void _deleteSupplier() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            const Text('Você tem certeza que deseja excluir este fornecedor?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Excluir'),
            onPressed: () async {
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final userId = authViewModel.currentUser!.id;
              await Provider.of<SupplierViewModel>(context, listen: false)
                  .deleteSupplier(userId, widget.supplier.id!);

              if (!mounted) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Fornecedor' : 'Detalhes'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSupplier,
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: !_isEditing,
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
                  isEditing: _isEditing,
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0))
                    : const Text('Salvar Alterações'),
              )
            ]
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
