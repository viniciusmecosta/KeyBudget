import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/theme/app_semantic_colors.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_status_badge.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
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

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  String? _avatarPath;
  String? _imagePickerError;
  String? _inlineError;
  bool _isEmailAlreadyInUse = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isOptionalExpanded = false;
  bool _hasSubmitted = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool get _hasUnsavedData {
    return _nameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _avatarPath != null;
  }

  bool get _hasOptionalData {
    return (_avatarPath != null && _avatarPath!.isNotEmpty) ||
        _phoneController.text.trim().isNotEmpty;
  }

  void _submit() async {
    setState(() {
      _hasSubmitted = true;
      _inlineError = null;
      _isEmailAlreadyInUse = false;
    });

    final phoneText = _phoneController.text.trim();
    final unmaskedPhone = _phoneMaskFormatter.getUnmaskedText();
    final isPhoneInvalid = phoneText.isNotEmpty && unmaskedPhone.length < 10;
    if (isPhoneInvalid) {
      setState(() => _isOptionalExpanded = true);
    }

    if (!_formKey.currentState!.validate()) {
      if (_nameController.text.trim().isEmpty) {
        _nameFocusNode.requestFocus();
      } else if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        _emailFocusNode.requestFocus();
      } else if (_passwordController.text.length < 6) {
        _passwordFocusNode.requestFocus();
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordFocusNode.requestFocus();
      } else if (isPhoneInvalid) {
        _phoneFocusNode.requestFocus();
      }
      return;
    }

    final authViewModel = ref.read(authViewModelProvider);
    final phone = _phoneController.text.isNotEmpty
        ? _phoneMaskFormatter.unmaskText(_phoneController.text)
        : null;

    final success = await authViewModel.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: phone,
      avatarPath: _avatarPath,
    );

    if (mounted) {
      if (success) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      } else {
        final errorMsg = authViewModel.errorMessage ?? 'Erro ao cadastrar.';
        setState(() {
          _inlineError = errorMsg;
          _isEmailAlreadyInUse = errorMsg.contains('já existe') ||
              errorMsg.contains('already-in-use');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final isRegistering = viewModel.isOperating(AuthOperation.register);

    final password = _passwordController.text;
    final hasMinLength = password.length >= 6;
    final hasLeadingOrTrailingSpaces =
        password.startsWith(' ') || password.endsWith(' ');

    return PopScope(
      canPop: !_hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Descartar cadastro?'),
            content: const Text(
              'Você preencheu dados no cadastro. Deseja sair e descartar as informações?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Continuar preenchendo'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AuthPageLayout(
        title: 'Crie sua conta',
        subtitle: 'Comece com seus dados essenciais.',
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
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Entrar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _hasSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'Nome completo',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Insira seu nome completo'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'E-mail',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Insira seu e-mail';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Insira um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  label: 'Senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      _confirmPasswordFocusNode.requestFocus(),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: _isPasswordVisible
                        ? 'Ocultar senha'
                        : 'Mostrar senha',
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasMinLength
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: hasMinLength
                                ? (semanticColors?.success ?? Colors.green)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Mínimo de 6 caracteres',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasMinLength
                                  ? (semanticColors?.success ?? Colors.green)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (hasLeadingOrTrailingSpaces) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: semanticColors?.warning ?? Colors.orange,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Atenção: sua senha contém espaços no início ou fim.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      semanticColors?.warning ?? Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  label: 'Confirmar senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: _isOptionalExpanded
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_isOptionalExpanded) {
                      _phoneFocusNode.requestFocus();
                    } else {
                      _submit();
                    }
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: _isConfirmPasswordVisible
                        ? 'Ocultar senha'
                        : 'Mostrar senha',
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: AppBorders.borderRadiusM,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          borderRadius: AppBorders.borderRadiusS,
                          onTap: () {
                            setState(() {
                              _isOptionalExpanded = !_isOptionalExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                _isOptionalExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _hasOptionalData
                                      ? 'Foto e telefone (adicionados)'
                                      : 'Adicionar foto e telefone (opcional)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_hasOptionalData && !_isOptionalExpanded)
                                AppStatusBadge(
                                  label: _avatarPath != null &&
                                          _phoneController.text.isNotEmpty
                                      ? '2 adicionados'
                                      : '1 adicionado',
                                  variant: AppBadgeVariant.info,
                                ),
                            ],
                          ),
                        ),
                        if (_isOptionalExpanded) ...[
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: Column(
                              children: [
                                ImagePickerWidget(
                                  initialImagePath: _avatarPath,
                                  onImageSelected: (path) {
                                    setState(() {
                                      _avatarPath = path.isEmpty ? null : path;
                                      _imagePickerError = null;
                                    });
                                  },
                                  onImageRemoved: () {
                                    setState(() {
                                      _avatarPath = null;
                                      _imagePickerError = null;
                                    });
                                  },
                                  onError: (error) {
                                    setState(() {
                                      _imagePickerError = error;
                                    });
                                  },
                                ),
                                if (_avatarPath != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _avatarPath = null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Remover foto'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_imagePickerError != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _imagePickerError!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            label: 'Telefone (opcional)',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            inputFormatters: [
                              PasteSanitizerInputFormatter(),
                              _phoneMaskFormatter,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final unmasked =
                                  _phoneMaskFormatter.getUnmaskedText();
                              if (unmasked.isNotEmpty && unmasked.length < 10) {
                                return 'Informe o DDD e o número completo';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _inlineError!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isEmailAlreadyInUse) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).maybePop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      theme.colorScheme.onErrorContainer,
                                ),
                                child: const Text(
                                  'Entrar com esta conta',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: isRegistering ? 'Criando conta...' : 'Criar conta',
                  isFullWidth: true,
                  isLoading: isRegistering,
                  onPressed: viewModel.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
