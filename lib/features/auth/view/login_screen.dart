import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
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
  bool _isPasswordVisible = false;

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
          context,
          authViewModel.errorMessage ??
              'Erro ao fazer login. Verifique suas credenciais.');
      _passwordController.clear();
    }
  }

  void _submitGoogle() async {
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginWithGoogle();
    if (mounted && !success) {
      SnackbarService.showError(context,
          authViewModel.errorMessage ?? 'Erro ao fazer login com Google.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return AuthPageLayout(
      title: "Bem-vindo de volta",
      subtitle: "Faça login para continuar",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Insira um email válido'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              label: 'Senha',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'A senha deve ter pelo menos 6 caracteres'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Entrar',
              isFullWidth: true,
              isLoading: viewModel.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Entrar com Google',
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              isLoading: viewModel.isLoading,
              onPressed: _submitGoogle,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Não tem uma conta? Cadastre-se',
              variant: AppButtonVariant.ghost,
              onPressed: () {
                NavigationUtils.push(context, const RegisterScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}
