import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/view/widgets/saved_logos_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

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
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  bool _decryptionError = false;

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
    _phoneController =
        TextEditingController(text: widget.credential.phoneNumber);
    _notesController = TextEditingController(text: widget.credential.notes);
    _logoPath = widget.credential.logoPath;
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
    if (!_isEditing) return;

    final text = _loginController.text;
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text);
    final isPhone = RegExp(r'^[0-9]+$').hasMatch(text);

    if (text.isEmpty) {
      _emailController.clear();
      _phoneController.clear();
    } else {
      if (isEmail) {
        _emailController.text = text;
      }
      if (isPhone) {
        _phoneController.text = text;
      }
    }
  }

  void _copyToClipboard(String text, {bool isPassword = false}) {
    if (isPassword && _decryptionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Não é possível copiar a senha com erro.'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência!')),
    );
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    await Provider.of<CredentialViewModel>(context, listen: false)
        .updateCredential(
      userId: userId,
      originalCredential: widget.credential,
      location: _locationController.text,
      login: _loginController.text,
      newPlainPassword: _passwordController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      notes: _notesController.text,
      logoPath: _logoPath,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      Navigator.of(context).pop();
    }
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
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final userId = authViewModel.currentUser!.id;
              await Provider.of<CredentialViewModel>(context, listen: false)
                  .deleteCredential(userId, widget.credential.id!);

              if (mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Credencial' : 'Detalhes'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCredential,
            ),
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
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: LogoPicker(
                    initialImagePath: _logoPath,
                    onImageSelected: (path) {
                      setState(() {
                        _logoPath = path;
                      });
                    },
                  ),
                ),
              ),
              if (_isEditing) ...[
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
                          foregroundColor: theme.colorScheme.error),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _locationController,
                readOnly: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                style: _isEditing
                    ? null
                    : TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Local/Serviço *',
                  suffixIcon: _isEditing
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_locationController.text),
                        ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                readOnly: !_isEditing,
                style: _isEditing
                    ? null
                    : TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Login/Usuário *',
                  suffixIcon: _isEditing
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              _copyToClipboard(_loginController.text),
                        ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                readOnly: !_isEditing,
                obscureText: !_isPasswordVisible,
                style: _isEditing
                    ? null
                    : TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  errorText: _decryptionError && !_isEditing
                      ? 'Erro ao decifrar.'
                      : null,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => _copyToClipboard(
                              _passwordController.text,
                              isPassword: true),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isEditing || _emailController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _emailController.text.isNotEmpty)
                TextFormField(
                  controller: _emailController,
                  readOnly: !_isEditing,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    suffixIcon: _isEditing || _emailController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copyToClipboard(_emailController.text),
                          ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              if (_isEditing || _phoneController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _phoneController.text.isNotEmpty)
                TextFormField(
                  controller: _phoneController,
                  readOnly: !_isEditing,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Número',
                    suffixIcon: _isEditing || _phoneController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copyToClipboard(_phoneController.text),
                          ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              if (_isEditing || _notesController.text.isNotEmpty)
                const SizedBox(height: 16),
              if (_isEditing || _notesController.text.isNotEmpty)
                TextFormField(
                  controller: _notesController,
                  readOnly: !_isEditing,
                  maxLines: 3,
                  style: _isEditing
                      ? null
                      : TextStyle(color: theme.colorScheme.onSurface),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    suffixIcon: _isEditing || _notesController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copyToClipboard(_notesController.text),
                          ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2.0))
                      : const Text('Salvar Alterações'),
                )
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
