import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/services/drive_connection_service.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class DriveConnectionScreen extends ConsumerStatefulWidget {
  const DriveConnectionScreen({super.key, this.driveService});

  final DriveService? driveService;

  @override
  ConsumerState<DriveConnectionScreen> createState() =>
      _DriveConnectionScreenState();
}

class _DriveConnectionScreenState extends ConsumerState<DriveConnectionScreen> {
  bool _isLoading = true;
  bool _isBusy = false;
  bool _isAuthorized = false;
  DriveConnection? _connection;
  String? _error;

  DriveService get _drive =>
      widget.driveService ??
      DriveService(
        connectionService: ref.read(driveConnectionServiceProvider),
        allowUserInteraction: true,
      );

  String? get _userId => ref.read(authViewModelProvider).currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = _userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Entre na sua conta para conectar o Drive.';
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authorized = await _drive.ensureAuthorized(allowInteractive: false);
      final connection = await ref
          .read(driveConnectionServiceProvider)
          .readConnection(userId);
      if (!mounted || _userId != userId) return;
      setState(() {
        _connection = connection;
        _isAuthorized = authorized;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Não foi possível verificar a conexão. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connect() async {
    if (_isBusy) return;
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final authorized = await _drive.ensureAuthorized();
      final connection = await ref
          .read(driveConnectionServiceProvider)
          .readConnection(userId);
      if (!mounted || _userId != userId) return;
      setState(() {
        _isAuthorized = authorized;
        _connection = connection;
        _error = authorized
            ? null
            : 'Não foi possível conectar ao Drive. Confira a conexão e tente novamente.';
      });
    } on DriveAuthorizationCancelled {
      return;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível conectar ao Drive. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _disconnect() async {
    if (_isBusy) return;
    final userId = _userId;
    if (userId == null) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(driveConnectionServiceProvider).disconnect(userId);
      if (!mounted || _userId != userId) return;
      setState(() {
        _connection = const DriveConnection.disabled();
        _isAuthorized = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Não foi possível desconectar o Drive. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = _connection?.enabled == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Google Drive')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: theme.colorScheme.primary,
                      size: 36,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _isAuthorized
                          ? 'Drive conectado'
                          : saved
                          ? 'Conexão salva'
                          : 'Conecte seu Google Drive',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Uma conexão para seus documentos e backups. O acesso é reutilizado ao abrir o aplicativo.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (saved) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _connection!.email,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (!_isAuthorized)
                        const Text(
                          'Confira a internet ou reconecte para renovar o acesso.',
                        ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      AppButton(
                        label: _isAuthorized
                            ? 'Verificar conexão'
                            : saved
                            ? 'Reconectar Google Drive'
                            : 'Conectar Google Drive',
                        isFullWidth: true,
                        isLoading: _isBusy,
                        onPressed: _isBusy
                            ? null
                            : _isAuthorized
                            ? _load
                            : _connect,
                      ),
                      if (saved) ...[
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: _isBusy ? null : _disconnect,
                          child: const Text('Desconectar Drive'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
