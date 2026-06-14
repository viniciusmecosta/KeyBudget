import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/password_form_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/view/register_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../widgets/auth_page_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final authViewModel = ref.read(authViewModelProvider);
    if (authViewModel.currentUser == null) {
      await authViewModel.authenticateWithBiometrics();
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted && !success) {
      SnackbarService.showError(
          context, authViewModel.errorMessage ?? 'Erro desconhecido');
      _passwordController.clear();
    }
  }

  void _submitGoogle() async {
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginWithGoogle();
    if (mounted && !success) {
      SnackbarService.showError(
          context, authViewModel.errorMessage ?? 'Erro desconhecido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthPageLayout(
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Insira um email válido'
                      : null,
                ),
                const SizedBox(height: AppTheme.spaceM),
                PasswordFormField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  validator: (value) => (value == null || value.length < 6)
                      ? 'A senha deve ter pelo menos 6 caracteres'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Consumer(
            builder: (context, ref, _) {
              final viewModel = ref.watch(authViewModelProvider);
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _submit,
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: AppTheme.spaceL,
                              width: AppTheme.spaceL,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading ? null : _submitGoogle,
                      icon: const FaIcon(
                        FontAwesomeIcons.google,
                        size: 20,
                      ),
                      label: const Text('Entrar com Google'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceL),
          TextButton(
            onPressed: () {
              NavigationUtils.push(context, const RegisterScreen());
            },
            child: Text(
              "Não tem uma conta? Cadastre-se",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),
    );
  }
}
