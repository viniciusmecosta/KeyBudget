import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/widget_to_image.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/credential_form.dart';

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
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  String? _logoPath;
  String? _selectedFolderId;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isExporting = false;
  bool _decryptionError = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final decryptedPassword =
        Provider.of<CredentialViewModel>(context, listen: false)
            .decryptPassword(widget.credential.encryptedPassword);

    _decryptionError = decryptedPassword == 'ERRO_DECRIPT';

    _locationController =
        TextEditingController(text: widget.credential.location);
    _loginController = TextEditingController(text: widget.credential.login);
    _passwordController = TextEditingController(
        text: _decryptionError ? 'Falha ao decifrar' : decryptedPassword);
    _emailController = TextEditingController(text: widget.credential.email);
    _phoneController = TextEditingController(
        text:
            _phoneMaskFormatter.maskText(widget.credential.phoneNumber ?? ''));
    _notesController = TextEditingController(text: widget.credential.notes);
    _logoPath = widget.credential.logoPath;
    _selectedFolderId = widget.credential.folderId;
  }

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

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final scaffoldContext = context;
    final navigator = Navigator.of(context);
    final userId = authViewModel.currentUser!.id;

    await viewModel.updateCredential(
      userId: userId,
      originalCredential: widget.credential,
      location: _locationController.text,
      login: _loginController.text,
      newPlainPassword: _passwordController.text,
      email: _emailController.text,
      phoneNumber: _phoneMaskFormatter.unmaskText(_phoneController.text),
      notes: _notesController.text,
      logoPath: _logoPath,
      folderId: _selectedFolderId,
    );

    if (!scaffoldContext.mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    SnackbarService.showSuccess(
        scaffoldContext, 'Credencial atualizada com sucesso!');
    navigator.pop();
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
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final viewModel =
                  Provider.of<CredentialViewModel>(context, listen: false);
              final scaffoldContext = context;
              final dialogNavigator = Navigator.of(ctx);
              final screenNavigator = Navigator.of(context);

              final userId = authViewModel.currentUser!.id;
              await viewModel.deleteCredential(userId, widget.credential.id!);

              if (!scaffoldContext.mounted) return;
              SnackbarService.showSuccess(
                  scaffoldContext, 'Credencial excluída com sucesso!');
              dialogNavigator.pop();
              screenNavigator.pop();
            },
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Exportar com fundo claro',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportCredential(false);
                },
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Exportar com fundo escuro',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportCredential(true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCredential(bool isDark) async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();

    final exportTheme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    final ticketWidget = _buildCredentialTicket(exportTheme);

    final bytes = await WidgetToImage.captureWidgetFromProvider(
      context,
      ticketWidget,
      wait: const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    if (bytes != null) {
      try {
        final directory = await getTemporaryDirectory();
        final sanitizedName =
            widget.credential.location.replaceAll(RegExp(r'\W+'), '_');
        final imagePath = '${directory.path}/credencial_$sanitizedName.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Credencial: ${widget.credential.location}',
        );
      } catch (e) {
        SnackbarService.showError(
            context, 'Erro ao compartilhar a credencial.');
      }
    } else {
      SnackbarService.showError(context, 'Erro ao gerar a imagem.');
    }

    setState(() => _isExporting = false);
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.lock_outline,
        color: theme.colorScheme.primary,
        size: 28,
      ),
    );
  }

  Widget _buildLogoWidget(String pathOrBase64, ThemeData theme) {
    bool isBase64 = pathOrBase64.length > 500;
    String cleanBase64 = pathOrBase64;

    if (isBase64 && cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(cleanBase64),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return _buildFallbackIcon(theme);
      }
    } else {
      return Image.file(
        File(pathOrBase64),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(theme),
      );
    }
  }

  Widget _buildCredentialTicket(ThemeData theme) {
    return Theme(
      data: theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_logoPath != null && _logoPath!.trim().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildLogoWidget(_logoPath!, theme),
                      )
                    else
                      _buildFallbackIcon(theme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _locationController.text.trim(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 24),
                if (_loginController.text.trim().isNotEmpty)
                  _buildTicketRow(Icons.person, 'Login',
                      _loginController.text.trim(), theme),
                if (_passwordController.text.trim().isNotEmpty)
                  _buildTicketRow(Icons.vpn_key, 'Senha',
                      _passwordController.text.trim(), theme),
                if (_emailController.text.trim().isNotEmpty)
                  _buildTicketRow(Icons.email, 'E-mail',
                      _emailController.text.trim(), theme),
                if (_phoneController.text
                    .replaceAll(RegExp(r'[^0-9]'), '')
                    .isNotEmpty)
                  _buildTicketRow(Icons.phone, 'Telefone',
                      _phoneController.text.trim(), theme),
                if (_notesController.text.trim().isNotEmpty)
                  _buildTicketRow(Icons.notes, 'Observações',
                      _notesController.text.trim(), theme),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'GERADO VIA KEYBUDGET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CredentialViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Credencial' : 'Detalhes'),
        actions: [
          if (!_isEditing) ...[
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Exportar como imagem',
                    onPressed: _showExportOptions,
                  ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCredential,
            ),
          ],
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
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
      body: AppAnimations.fadeInFromBottom(Padding(
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
                isEditing: _isEditing,
                availableFolders: vm.allFolders,
                selectedFolderId: _selectedFolderId,
                onFolderChanged: (folderId) {
                  setState(() {
                    _selectedFolderId = folderId;
                  });
                },
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0))
                    : const Text('Salvar Alterações'),
              )
            ]
          ],
        ),
      )),
    );
  }
}
