import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/core/utils/formatters.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/auth/widgets/auth_page_layout.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _avatarPath;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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

    final authViewModel = ref.read(authViewModelProvider);

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
            context, authViewModel.errorMessage ?? 'Erro ao cadastrar.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return AuthPageLayout(
      title: "Criar Conta",
      subtitle: "Preencha seus dados para começar",
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ImagePickerWidget(
              onImageSelected: (path) {
                _avatarPath = path;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _nameController,
              label: 'Nome completo *',
              prefixIcon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Insira seu nome'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailController,
              label: 'Email *',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Insira um email válido'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              label: 'Telefone (Opcional)',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PasteSanitizerInputFormatter(),
                _phoneMaskFormatter,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              label: 'Senha *',
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
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar Senha *',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              validator: (value) => value != _passwordController.text
                  ? 'As senhas não coincidem'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Cadastrar',
              isFullWidth: true,
              isLoading: viewModel.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Já tem uma conta? Faça login',
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
