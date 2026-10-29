import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_button.dart';
import 'package:passfin/core/services/drive_connection_service.dart';
import 'package:passfin/core/services/drive_service.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';

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
  String? _verification;

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

  Future<void> _verify() async {
    if (_isBusy || _isLoading) return;
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _isBusy = true;
      _verification = null;
      _error = null;
    });
    try {
      final authorized = await _drive.verifyConnection().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted || _userId != userId) return;
      setState(() {
        _isAuthorized = authorized;
        _verification = authorized
            ? 'Conexão verificada. Seu Google Drive está acessível.'
            : null;
        _error = authorized
            ? null
            : 'O acesso expirou. Reconecte seu Google Drive para continuar.';
      });
    } catch (_) {
      if (!mounted || _userId != userId) return;
      setState(() {
        _isAuthorized = false;
        _error =
            'O Drive não respondeu. Confira sua internet e tente reconectar.';
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _connect() async {
    if (_isBusy) return;
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _isBusy = true;
      _verification = null;
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
    setState(() {
      _isBusy = true;
      _verification = null;
    });
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
    return AppPageScaffold(
      appBar: AppBar(title: const Text('Google Drive')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
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
                    if (_verification != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _verification!,
                          style: theme.textTheme.bodyMedium,
                        ),
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
                            ? _verify
                            : _connect,
                      ),
                      if (saved) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          variant: AppButtonVariant.outline,
                          isFullWidth: true,
                          onPressed: _isBusy ? null : _disconnect,
                          label: 'Desconectar Drive',
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
