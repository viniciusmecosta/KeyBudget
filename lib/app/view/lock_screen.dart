import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
import 'package:key_budget/core/design_system/widgets/passfin_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_centered_scroll.dart';

class LockScreen extends ConsumerStatefulWidget {
  final LocalAuthService? localAuthService;

  const LockScreen({super.key, this.localAuthService});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _isSigningOut = false;
  bool _didPromptAutomatically = false;
  LocalAuthAvailability? _availability;
  String? _statusFeedback;
  late final LocalAuthService _localAuthService;

  @override
  void initState() {
    super.initState();
    _localAuthService = widget.localAuthService ?? LocalAuthService();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAvailabilityAndPrompt();
      }
    });
  }

  Future<void> _checkAvailabilityAndPrompt() async {
    LocalAuthAvailability availability;
    try {
      availability = await _localAuthService.checkAvailability();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _statusFeedback =
            'Não foi possível consultar a proteção do dispositivo. Tente desbloquear novamente.',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _availability = availability);

    _promptAutomaticallyOnce();
  }

  void _promptAutomaticallyOnce() {
    if (_didPromptAutomatically ||
        _availability == null ||
        _availability == LocalAuthAvailability.notSupported ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _didPromptAutomatically = true;
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      _promptAutomaticallyOnce();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || _isSigningOut) return;

    _didPromptAutomatically = true;
    final startUid = ref.read(authViewModelProvider).currentUser?.id;
    setState(() {
      _isAuthenticating = true;
      _statusFeedback = null;
    });

    final appLockService = ref.read(appLockServiceProvider);
    appLockService.isAuthenticating = true;

    try {
      final result = await _localAuthService.authenticateLocal();

      if (!mounted) return;
      final currentUid = ref.read(authViewModelProvider).currentUser?.id;
      if (currentUid != startUid) {
        setState(() => _isAuthenticating = false);
        return;
      }

      switch (result) {
        case LocalAuthResult.success:
          ref.read(appLockServiceProvider).unlockApp();
          break;
        case LocalAuthResult.cancelled:
          setState(() {
            _isAuthenticating = false;
          });
          break;
        case LocalAuthResult.temporarilyLockedOut:
          setState(() {
            _isAuthenticating = false;
            _statusFeedback =
                'Muitas tentativas. Aguarde alguns instantes antes de tentar.';
          });
          break;
        case LocalAuthResult.permanentlyLockedOut:
          setState(() {
            _isAuthenticating = false;
            _statusFeedback =
                'Biometria bloqueada. Use a senha do dispositivo ou saia da conta.';
          });
          break;
        case LocalAuthResult.notAvailable:
          setState(() {
            _isAuthenticating = false;
            _availability = LocalAuthAvailability.notSupported;
            _statusFeedback =
                'Autenticação biométrica/PIN não disponível neste dispositivo.';
          });
          break;
        case LocalAuthResult.failed:
          setState(() {
            _isAuthenticating = false;
            _statusFeedback = 'Não foi possível confirmar. Tente novamente.';
          });
          break;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _statusFeedback = 'Erro inesperado na verificação.';
        });
      }
    } finally {
      appLockService.isAuthenticating = false;
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut || _isAuthenticating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar seus dados. Os dados salvos na conta serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = ref.read(authViewModelProvider);
    final lock = ref.read(appLockServiceProvider);
    setState(() {
      _isSigningOut = true;
      _statusFeedback = null;
    });
    try {
      await auth.logout(context, ref);
      if (auth.currentUser == null) lock.unlockApp();
    } catch (_) {
      if (mounted) {
        setState(
          () => _statusFeedback =
              'Não foi possível sair da conta. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPageScaffold(
      maxContentWidth: 600,
      body: SafeArea(
        child: AppAnimations.fadeIn(
          AppCenteredScroll(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PassFinBrand(width: 112),
                const SizedBox(height: 28),
                Text(
                  'PassFin bloqueado',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confirme sua identidade para continuar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_availability == LocalAuthAvailability.notSupported) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Desbloqueio indisponível neste dispositivo. Entre novamente na sua conta.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_statusFeedback != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusFeedback!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (_availability != LocalAuthAvailability.notSupported)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: _isAuthenticating || _isSigningOut
                          ? null
                          : _authenticate,
                      isLoading: _isAuthenticating,
                      label: 'Desbloquear',
                      icon: Icons.fingerprint,
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _isAuthenticating || _isSigningOut
                      ? null
                      : _signOut,
                  icon: Icon(
                    Icons.logout,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Sair da Conta',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          context: context,
        ),
      ),
    );
  }
}
