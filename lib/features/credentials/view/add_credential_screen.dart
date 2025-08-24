import 'package:flutter/material.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

class AddCredentialScreen extends StatefulWidget {
  const AddCredentialScreen({super.key});

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _logoPath;
  bool _isPasswordVisible = false;
  bool _isSaving = false;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final credentialViewModel =
        Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    credentialViewModel
        .addCredential(
      userId: authViewModel.currentUser!.id!,
      location: _locationController.text,
      login: _loginController.text,
      plainPassword: _passwordController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber:
          _phoneController.text.isNotEmpty ? _phoneController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      logoPath: _logoPath,
    )
        .whenComplete(() {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Credencial')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: LogoPicker(onImageSelected: (path) {
                  _logoPath = path;
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Local/Serviço *'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: 'Login/Usuário *'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Senha *',
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (opcional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration:
                    const InputDecoration(labelText: 'Número (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Observações (opcional)'),
                maxLines: 3,
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
                    : const Text('Salvar Credencial'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
