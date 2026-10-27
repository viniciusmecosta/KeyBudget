import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
import 'package:key_budget/core/security/vault_crypto.dart';
import 'package:key_budget/core/security/vault_session.dart';
import 'package:key_budget/features/credentials/application/vault_migration_service.dart';

class VaultMigrationScreen extends ConsumerStatefulWidget {
  const VaultMigrationScreen({super.key});

  @override
  ConsumerState<VaultMigrationScreen> createState() =>
      _VaultMigrationScreenState();
}

class _VaultMigrationScreenState extends ConsumerState<VaultMigrationScreen>
    with WidgetsBindingObserver {
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _revealed = <int>{};
  VaultMigrationService? _service;
  VaultMigrationPreview? _preview;
  bool _busy = false;
  bool _confirmed = false;
  bool _showKey = false;
  String? _error;
  String _progress = '';
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = ref.read(vaultSessionProvider).migrationService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _keyController.clear();
      _revealed.clear();
      _showKey = false;
      if (!_busy) {
        _service?.discardPreview();
        _preview = null;
        _confirmed = false;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service?.discardPreview();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testKey() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _confirmed = false;
      _revealed.clear();
    });
    try {
      final input = _keyController.text;
      _keyController.clear();
      final preview = await _service!.preview(
        input,
        currentCipher: ref.read(vaultSessionProvider).recoveryCipher,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        if (!preview.canProceed) {
          _error = preview.failures.isEmpty
              ? 'Nenhuma senha legada foi encontrada para migrar.'
              : 'Não foi possível ler ${preview.failures.length} senha(s). Confira a chave. Nenhum dado foi alterado.';
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safeError(Object error) => error is VaultException
      ? error.message
      : 'Não foi possível concluir esta etapa. Seus dados e o progresso salvo foram preservados. Confira a conexão e tente novamente.';

  void _onProgress(String message, int done, int total) {
    if (mounted) {
      setState(() {
        _progress = message;
        _done = done;
        _total = total;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final session = ref.read(vaultSessionProvider);
    final uid = session.userId;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Preparando a proteção';
      _done = 0;
      _total = 0;
      _revealed.clear();
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      _service?.discardPreview();
      _preview = null;
      _confirmed = false;
      if (session.userId == uid) await session.open(uid);
      if (mounted) {
        if (session.userId == uid) _service = session.migrationService();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rollback() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desfazer a migração?'),
        content: const Text(
          'As senhas voltarão ao formato original. Para lê-las nesse formato, será necessário informar a chave antiga novamente. O backup e a chave nova serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = ref.read(vaultSessionProvider).migrationId!;
    await _run(() => _service!.rollback(id, onProgress: _onProgress));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultSessionProvider);
    final preview = _preview;
    final ready = session.status == VaultStatus.ready;
    final recoverable = session.needsRecovery && session.hasVerifiedBackup;
    final entries = preview?.entries ?? const <VaultPreviewEntry>[];
    final showInput = !ready && !recoverable && !_busy && preview == null;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: AppPageScaffold(
        maxContentWidth: 760,
        appBar: AppBar(
          title: Text(
            ready
                ? 'Proteção do cofre'
                : session.hasVersionedKey
                ? 'Retomar migração'
                : 'Incluir chave legada',
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      ready ? Icons.verified_user_outlined : Icons.key_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ready
                          ? 'Proteção atualizada e verificada'
                          : 'Atualize a proteção das suas senhas',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ready
                          ? 'Sua chave individual está salva na sua conta. O login recupera o acesso automaticamente.'
                          : 'Primeiro teste a chave antiga e confira as senhas. Após sua confirmação, criaremos uma chave individual e um backup verificado antes de atualizar os dados.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    if (_busy) ...[
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: _total > 0 ? _done / _total : null,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          '$_progress${_total > 0 ? ' · $_done de $_total' : ''}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aguarde esta etapa terminar. Se o aplicativo fechar, o progresso salvo permitirá retomar.',
                      ),
                    ],
                    if (ready && session.hasVerifiedBackup && !_busy) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'O backup anterior à atualização está preservado na sua conta. Você pode desfazer a migração sem apagar a chave nova ou o backup.',
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Desfazer migração',
                        variant: AppButtonVariant.outline,
                        onPressed: _rollback,
                        isFullWidth: true,
                      ),
                    ],
                    if (showInput) ...[
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _keyController,
                          obscureText: !_showKey,
                          autocorrect: false,
                          enableSuggestions: false,
                          enableIMEPersonalizedLearning: false,
                          decoration: InputDecoration(
                            labelText: 'Chave legada',
                            errorMaxLines: 3,
                            helperText:
                                'Somente o valor da chave: 32 caracteres. Espaços nas bordas serão removidos.',
                            helperMaxLines: 3,
                            suffixIcon: IconButton(
                              tooltip: _showKey
                                  ? 'Ocultar chave'
                                  : 'Mostrar chave',
                              onPressed: () =>
                                  setState(() => _showKey = !_showKey),
                              icon: Icon(
                                _showKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (input) {
                            try {
                              normalizeLegacyKey(input ?? '');
                              return null;
                            } on VaultException catch (error) {
                              return error.message;
                            }
                          },
                          onFieldSubmitted: (_) => _testKey(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Testar chave',
                        icon: Icons.fact_check_outlined,
                        onPressed: _testKey,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A chave antiga é usada temporariamente e não será salva.',
                      ),
                    ],
                    if (recoverable && !_busy) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'O backup foi salvo e verificado. Você pode retomar sem informar a chave antiga ou desfazer as alterações realizadas.',
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: session.isRollingBack
                            ? 'Continuar desfazer'
                            : 'Retomar migração',
                        icon: Icons.play_arrow,
                        isFullWidth: true,
                        onPressed: () => _run(
                          () => session.isRollingBack
                              ? _service!.rollback(
                                  session.migrationId!,
                                  onProgress: _onProgress,
                                )
                              : _service!.resume(
                                  session.migrationId!,
                                  onProgress: _onProgress,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Desfazer migração',
                        variant: AppButtonVariant.outline,
                        onPressed: _rollback,
                        isFullWidth: true,
                      ),
                    ],
                    if (preview != null && !_busy) ...[
                      const SizedBox(height: 24),
                      Text(
                        '${entries.length} senha(s) lida(s), incluindo ${entries.where((e) => e.inTrash).length} na lixeira.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'O formato antigo não comprova a integridade. Revele e confira as senhas antes de autorizar a atualização.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!_busy)
              SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final revealed = _revealed.contains(index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          entry.inTrash ? Icons.delete_outline : Icons.password,
                        ),
                        title: Text(entry.label),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.inTrash) const Text('Na lixeira'),
                            if (revealed)
                              SelectableText(
                                entry.plaintext.isEmpty
                                    ? '(senha vazia)'
                                    : entry.plaintext,
                              )
                            else
                              const Text('••••••••••••'),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: revealed
                              ? 'Ocultar senha'
                              : 'Conferir senha',
                          icon: Icon(
                            revealed ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() {
                            if (revealed) {
                              _revealed.remove(index);
                            } else {
                              _revealed.add(index);
                            }
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (preview != null && !_busy)
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _confirmed,
                        onChanged: preview.canProceed
                            ? (value) =>
                                  setState(() => _confirmed = value ?? false)
                            : null,
                        title: const Text(
                          'Conferi as senhas e autorizo criar o backup e atualizar a proteção.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Criar backup e migrar',
                        icon: Icons.shield_outlined,
                        isFullWidth: true,
                        onPressed: preview.canProceed && _confirmed
                            ? () => _run(
                                () => _service!.start(
                                  preview,
                                  confirmed: true,
                                  onProgress: _onProgress,
                                ),
                              )
                            : null,
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _service!.discardPreview();
                          _preview = null;
                          _confirmed = false;
                          _revealed.clear();
                        }),
                        child: const Text('Cancelar conferência'),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
