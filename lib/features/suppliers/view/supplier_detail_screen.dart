import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/view/widgets/saved_logos_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

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
    mask: '(##) # ####-####',
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

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência!')),
    );
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

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      Navigator.of(context).pop();
    }
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

              if (mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _selectSavedLogo() async {
    final selectedLogo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const SavedLogosScreen(),
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
    final theme = Theme.of(context);

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
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: LogoPicker(
                    initialImagePath: _photoPath,
                    onImageSelected: (path) {
                      setState(() {
                        _photoPath = path;
                      });
                    },
                  ),
                ),
              ),
              if (_isEditing) ...[
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
                          foregroundColor: theme.colorScheme.error),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                readOnly: !_isEditing,
                textCapitalization: TextCapitalization.words,
                style: _isEditing
                    ? null
                    : TextStyle(color: theme.colorScheme.onSurface),
                decoration:
                    const InputDecoration(labelText: 'Nome Fornecedor/Loja *'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              if (_isEditing || _repNameController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _repNameController.text.isNotEmpty)
                TextFormField(
                  controller: _repNameController,
                  readOnly: !_isEditing,
                  textCapitalization: TextCapitalization.words,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration:
                      const InputDecoration(labelText: 'Nome Representante'),
                ),
              if (_isEditing || _emailController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _emailController.text.isNotEmpty)
                TextFormField(
                  controller: _emailController,
                  readOnly: !_isEditing,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    suffixIcon: _isEditing || _emailController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copyToClipboard(_emailController.text),
                          ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
              if (_isEditing || _phoneController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _phoneController.text.isNotEmpty)
                TextFormField(
                  controller: _phoneController,
                  readOnly: !_isEditing,
                  inputFormatters: [_phoneMaskFormatter],
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Telefone (WhatsApp)',
                    suffixIcon: _isEditing || _phoneController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyToClipboard(
                              _phoneMaskFormatter
                                  .unmaskText(_phoneController.text),
                            ),
                          ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final unmaskedText =
                        _phoneMaskFormatter.unmaskText(_phoneController.text);
                    if (unmaskedText.isNotEmpty && unmaskedText.length != 11) {
                      return 'O telefone deve ter 11 dígitos.';
                    }
                    return null;
                  },
                ),
              if (_isEditing || _notesController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _notesController.text.isNotEmpty)
                TextFormField(
                  controller: _notesController,
                  readOnly: !_isEditing,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              const SizedBox(height: 24),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2.0))
                      : const Text('Salvar Alterações'),
                )
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
