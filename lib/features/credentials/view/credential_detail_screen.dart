import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../widgets/credential_form.dart';

class CredentialDetailScreen extends StatefulWidget {
  final Credential credential;

  const CredentialDetailScreen({super.key, required this.credential});

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationController;
  late TextEditingController _loginController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  String? _logoPath;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _decryptionError = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final decryptedPassword =
        Provider.of<CredentialViewModel>(context, listen: false)
            .decryptPassword(widget.credential.encryptedPassword);

    _decryptionError = decryptedPassword == 'ERRO_DECRIPT';

    _locationController =
        TextEditingController(text: widget.credential.location);
    _loginController = TextEditingController(text: widget.credential.login);
    _passwordController = TextEditingController(
        text: _decryptionError ? 'Falha ao decifrar' : decryptedPassword);
    _emailController = TextEditingController(text: widget.credential.email);
    _phoneController = TextEditingController(
        text:
            _phoneMaskFormatter.maskText(widget.credential.phoneNumber ?? ''));
    _notesController = TextEditingController(text: widget.credential.notes);
    _logoPath = widget.credential.logoPath;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
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

    await Provider.of<CredentialViewModel>(context, listen: false)
        .updateCredential(
      userId: userId,
      originalCredential: widget.credential,
      location: _locationController.text,
      login: _loginController.text,
      newPlainPassword: _passwordController.text,
      email: _emailController.text,
      phoneNumber: _phoneMaskFormatter.unmaskText(_phoneController.text),
      notes: _notesController.text,
      logoPath: _logoPath,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    Navigator.of(context).pop();
  }

  void _deleteCredential() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            const Text('Você tem certeza que deseja excluir esta credencial?'),
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
              await Provider.of<CredentialViewModel>(context, listen: false)
                  .deleteCredential(userId, widget.credential.id!);
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
        title: Text(_isEditing ? 'Editar Credencial' : 'Detalhes'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCredential,
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
              child: CredentialForm(
                formKey: _formKey,
                locationController: _locationController,
                loginController: _loginController,
                passwordController: _passwordController,
                emailController: _emailController,
                phoneController: _phoneController,
                notesController: _notesController,
                logoPath: _logoPath,
                onLogoChanged: (path) {
                  setState(() {
                    _logoPath = path;
                  });
                },
                isEditing: _isEditing,
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
