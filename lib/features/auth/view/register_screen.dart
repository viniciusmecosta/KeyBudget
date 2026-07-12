import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
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
  double _passwordStrength = 0;

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

  double _calcPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 10) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    return strength.clamp(0.0, 1.0);
  }

  Color _strengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.amber;
    return Colors.greenAccent[400]!;
  }

  String _strengthLabel(double strength) {
    if (strength <= 0.25) return 'Fraca';
    if (strength <= 0.5) return 'Razoável';
    if (strength <= 0.75) return 'Boa';
    return 'Forte';
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
          context,
          authViewModel.errorMessage ?? 'Erro ao cadastrar.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: "Criar Conta",
      subtitle: "Preencha seus dados para começar",
      showBackButton: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Já tem uma conta?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Faça login',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ImagePickerWidget(
                onImageSelected: (path) {
                  setState(() => _avatarPath = path);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _nameController,
              label: 'Nome completo *',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Insira seu nome' : null,
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
              onChanged: (value) {
                setState(() => _passwordStrength = _calcPasswordStrength(value));
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'A senha deve ter pelo menos 6 caracteres'
                  : null,
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _PasswordStrengthBar(
                strength: _passwordStrength,
                color: _strengthColor(_passwordStrength),
                label: _strengthLabel(_passwordStrength),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar Senha *',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
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
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;

  const _PasswordStrengthBar({
    required this.strength,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
