import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../widgets/credential_form.dart';

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
  bool _isSaving = false;

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
    final phoneMaskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

    if (text.isEmpty) {
      _emailController.clear();
      _phoneController.clear();
    } else {
      if (isEmail) {
        _emailController.text = text;
      }
      final sanitizedText = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (sanitizedText.length >= 10) {
        _phoneController.text = phoneMaskFormatter.maskText(sanitizedText);
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
    final phoneMaskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

    await credentialViewModel.addCredential(
      userId: userId,
      location: _locationController.text,
      login: _loginController.text,
      plainPassword: _passwordController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber: _phoneController.text.isNotEmpty
          ? phoneMaskFormatter.unmaskText(_phoneController.text)
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      logoPath: _logoPath,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Credencial')),
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
                  : const Text('Salvar Credencial'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
