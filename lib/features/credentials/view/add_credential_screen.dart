import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/view/widgets/saved_logos_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _loginController.addListener(_updateFields);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _loginController.removeListener(_updateFields);
    _loginController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateFields() {
    final text = _loginController.text;
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text);

    if (text.isEmpty) {
      _emailController.clear();
      _phoneController.clear();
    } else {
      if (isEmail) {
        _emailController.text = text;
      }
      final sanitizedText = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (sanitizedText.length >= 10) {
        _phoneController.text = _phoneMaskFormatter.maskText(sanitizedText);
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final credentialViewModel =
        Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    await credentialViewModel.addCredential(
      userId: userId,
      location: _locationController.text,
      login: _loginController.text,
      plainPassword: _passwordController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber: _phoneController.text.isNotEmpty
          ? _phoneMaskFormatter.unmaskText(_phoneController.text)
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      logoPath: _logoPath,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  void _selectSavedLogo() async {
    final selectedLogo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const SavedLogosScreen(),
      ),
    );

    if (selectedLogo != null) {
      setState(() {
        _logoPath = selectedLogo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Credencial')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: LogoPicker(
                  initialImagePath: _logoPath,
                  onImageSelected: (path) {
                    setState(() {
                      _logoPath = path;
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
                  if (_logoPath != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _logoPath = null;
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
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
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
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneMaskFormatter],
                decoration: const InputDecoration(labelText: 'Número'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Observações'),
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
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
