import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
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
  bool _isEditing = false;

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

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    Provider.of<CredentialViewModel>(context, listen: false)
        .updateCredential(
      originalCredential: widget.credential,
      location: _locationController.text,
      login: _loginController.text,
      newPlainPassword: _newPasswordController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      notes: _notesController.text,
    )
        .then((_) {
      if (mounted) Navigator.of(context).pop();
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
              Provider.of<CredentialViewModel>(context, listen: false)
                  .deleteCredential(
                      widget.credential.id!, widget.credential.userId)
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
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Local/Serviço *'),
                enabled: _isEditing,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: 'Login/Usuário *'),
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
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (opcional)'),
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration:
                    const InputDecoration(labelText: 'Número (opcional)'),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Observações (opcional)'),
                enabled: _isEditing,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
