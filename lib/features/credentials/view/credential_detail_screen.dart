import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController _newPasswordController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  String? _logoPath;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  late String _decryptedPassword;

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.credential.location);
    _loginController = TextEditingController(text: widget.credential.login);
    _newPasswordController = TextEditingController();
    _emailController = TextEditingController(text: widget.credential.email);
    _phoneController =
        TextEditingController(text: widget.credential.phoneNumber);
    _notesController = TextEditingController(text: widget.credential.notes);
    _logoPath = widget.credential.logoPath;

    _decryptedPassword =
        Provider.of<CredentialViewModel>(context, listen: false)
            .decryptPassword(widget.credential.encryptedPassword);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _loginController.dispose();
    _newPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência!')),
    );
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    Provider.of<CredentialViewModel>(context, listen: false)
        .updateCredential(
      userId: userId,
      originalCredential: widget.credential,
      location: _locationController.text,
      login: _loginController.text,
      newPlainPassword: _newPasswordController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      notes: _notesController.text,
      logoPath: _logoPath,
    )
        .whenComplete(() {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    });
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
            onPressed: () {
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final userId = authViewModel.currentUser!.id;
              Provider.of<CredentialViewModel>(context, listen: false)
                  .deleteCredential(userId, widget.credential.id!)
                  .then((_) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _logoPath != null && _logoPath!.isNotEmpty
        ? MemoryImage(base64Decode(_logoPath!))
        : null;

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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: _isEditing
                    ? LogoPicker(
                        initialImagePath: _logoPath,
                        onImageSelected: (path) {
                          setState(() {
                            _logoPath = path;
                          });
                        },
                      )
                    : CircleAvatar(
                        radius: 40,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.vpn_key_outlined, size: 30)
                            : null,
                      ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Local/Serviço *',
                  suffixIcon: !_isEditing
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_locationController.text),
                        )
                      : null,
                ),
                enabled: _isEditing,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: 'Login/Usuário *',
                  suffixIcon: !_isEditing
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_loginController.text),
                        )
                      : null,
                ),
                enabled: _isEditing,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                      labelText:
                          'Nova Senha (deixe em branco para não alterar)'),
                  obscureText: true,
                )
              else
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                      text: _isPasswordVisible
                          ? _decryptedPassword
                          : '••••••••••'),
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => _copyToClipboard(_decryptedPassword),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  suffixIcon: !_isEditing && _emailController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_emailController.text),
                        )
                      : null,
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Número',
                  suffixIcon: !_isEditing && _phoneController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_phoneController.text),
                        )
                      : null,
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  suffixIcon: !_isEditing && _notesController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_notesController.text),
                        )
                      : null,
                ),
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.0))
                      : const Text('Salvar Alterações'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
