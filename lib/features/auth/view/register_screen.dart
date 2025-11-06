import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/app/widgets/password_form_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/core/utils/formatters.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _avatarPath;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final success = await authViewModel.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: _phoneController.text.isNotEmpty
          ? _phoneMaskFormatter.unmaskText(_phoneController.text)
          : null,
      avatarPath: _avatarPath,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        SnackbarService.showError(
            context, authViewModel.errorMessage ?? 'Erro desconhecido');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Criar Conta',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: AppAnimations.fadeInFromBottom(Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppTheme.spaceXL),
                ImagePickerWidget(
                  onImageSelected: (path) {
                    _avatarPath = path;
                  },
                ),
                const SizedBox(height: AppTheme.spaceL),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Insira seu nome'
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceM),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Insira um email válido'
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceM),
                TextFormField(
                  controller: _phoneController,
                  inputFormatters: [
                    PasteSanitizerInputFormatter(),
                    _phoneMaskFormatter,
                  ],
                  decoration: const InputDecoration(labelText: 'Número'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spaceM),
                PasswordFormField(
                  controller: _passwordController,
                  labelText: 'Senha *',
                  validator: (value) => (value == null || value.length < 6)
                      ? 'A senha deve ter pelo menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceM),
                PasswordFormField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmar Senha *',
                  validator: (value) => value != _passwordController.text
                      ? 'As senhas não coincidem'
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Consumer<AuthViewModel>(
                  builder: (context, viewModel, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Cadastrar'),
                            ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Já tem uma conta? Faça login',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      )),
    );
  }
}
