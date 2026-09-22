import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/import_export/import_plan.dart';
import 'package:key_budget/core/import_export/raw_storage.dart';
import 'package:key_budget/core/import_export/restore_service.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:share_plus/share_plus.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _createPassController = TextEditingController();
  final _createConfirmPassController = TextEditingController();
  bool _obscureCreatePass = true;
  bool _isCreatingBackup = false;
  String _createProgressStatus = '';
  double _createProgressValue = 0.0;
  BackupResultData? _lastBackupResult;

  final Map<String, bool> _selectedModules = {
    'expenses': true,
    'recurring_expenses': true,
    'credentials': true,
    'categories': true,
    'folders': true,
    'suppliers': true,
    'documents': true,
    'profile': true,
  };

  final _restorePassController = TextEditingController();
  bool _obscureRestorePass = true;
  bool _isPreviewing = false;
  bool _isRestoring = false;
  String _restoreProgressStatus = '';
  double _restoreProgressValue = 0.0;
  Uint8List? _selectedRestoreBytes;
  String? _selectedRestoreFileName;
  ImportPlan? _importPlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createPassController.dispose();
    _createConfirmPassController.dispose();
    _restorePassController.dispose();
    super.dispose();
  }

  String _getModuleLabel(String key) {
    switch (key) {
      case 'expenses':
        return 'Despesas e Lançamentos';
      case 'recurring_expenses':
        return 'Despesas Recorrentes';
      case 'credentials':
        return 'Credenciais e Senhas do Cofre';
      case 'categories':
        return 'Categorias';
      case 'folders':
        return 'Pastas do Cofre';
      case 'suppliers':
        return 'Fornecedores';
      case 'documents':
        return 'Documentos e Versões';
      case 'profile':
        return 'Preferências do Perfil';
      default:
        return key;
    }
  }

  Future<void> _handleCreateBackup() async {
    final password = _createPassController.text;
    final confirmPassword = _createConfirmPassController.text;

    if (password.length < 6) {
      SnackbarService.showError(
        context,
        'A senha de proteção deve conter no mínimo 6 caracteres.',
      );
      return;
    }

    if (password != confirmPassword) {
      SnackbarService.showError(
        context,
        'A confirmação de senha não coincide com a senha informada.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackbarService.showError(context, 'Usuário não autenticado.');
      return;
    }

    setState(() {
      _isCreatingBackup = true;
      _createProgressStatus = 'Iniciando...';
      _createProgressValue = 0.0;
      _lastBackupResult = null;
    });

    try {
      final sessionContext = SessionContext(
        userId: user.uid,
        sessionGeneration: 1,
      );
      final rawReader = FirestoreRawStorage();
      final backupService = BackupService(
        rawReader: rawReader,
        sessionContext: sessionContext,
        encryptionService: EncryptionService(),
        driveService: DriveService(),
      );

      final selectedList = _selectedModules.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final result = await backupService.createBackup(
        password: password,
        selectedModules: selectedList,
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _createProgressStatus = status;
              _createProgressValue = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });

        if (result.isSuccess && result.data != null) {
          setState(() {
            _lastBackupResult = result.data;
          });
          SnackbarService.showSuccess(
            context,
            'Backup .kbudget gerado e verificado com sucesso!',
          );
        } else {
          SnackbarService.showError(
            context,
            result.safeError ?? 'Falha ao gerar backup.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
        SnackbarService.showError(context, 'Erro inesperado: $e');
      }
    }
  }

  Future<void> _shareBackupFile() async {
    if (_lastBackupResult?.localFile != null) {
      final file = _lastBackupResult!.localFile!;
      final params = ShareParams(
        files: [XFile(file.path)],
        text: 'Backup KeyBudget (.kbudget)',
      );
      await SharePlus.instance.share(params);
    }
  }

  Future<void> _uploadBackupToDrive() async {
    if (_lastBackupResult?.localFile == null) return;
    try {
      final driveService = DriveService();
      final res = await driveService.uploadFile(
        _lastBackupResult!.localFile!,
        (p0, p1) {},
        isBackup: true,
      );
      if (mounted) {
        if (res?.id != null) {
          SnackbarService.showSuccess(
            context,
            'Backup salvo na pasta Backup do Google Drive!',
          );
        } else {
          SnackbarService.showError(
            context,
            'Não foi possível realizar upload para o Google Drive.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Erro no upload: $e');
      }
    }
  }

  Future<void> _pickRestoreFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedRestoreBytes = bytes;
          _selectedRestoreFileName = result.files.first.name;
          _importPlan = null;
        });
      }
    }
  }

  Future<void> _handlePreviewRestore() async {
    if (_selectedRestoreBytes == null) {
      SnackbarService.showError(
        context,
        'Selecione um arquivo .kbudget para restauração.',
      );
      return;
    }

    final password = _restorePassController.text;
    if (password.isEmpty) {
      SnackbarService.showError(
        context,
        'Informe a senha de proteção do arquivo de backup.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackbarService.showError(context, 'Usuário não autenticado.');
      return;
    }

    setState(() {
      _isPreviewing = true;
      _importPlan = null;
    });

    try {
      final sessionContext = SessionContext(
        userId: user.uid,
        sessionGeneration: 1,
      );
      final rawStorage = FirestoreRawStorage();
      final restoreService = RestoreService(
        rawReader: rawStorage,
        rawWriter: rawStorage,
        sessionContext: sessionContext,
        encryptionService: EncryptionService(),
        driveService: DriveService(),
      );

      final result = await restoreService.previewRestore(
        backupBytes: _selectedRestoreBytes!,
        password: password,
      );

      if (mounted) {
        setState(() {
          _isPreviewing = false;
        });

        if (result.isSuccess && result.data != null) {
          setState(() {
            _importPlan = result.data;
          });
        } else {
          SnackbarService.showError(
            context,
            result.safeError ?? 'Falha ao analisar arquivo de backup.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPreviewing = false;
        });
        SnackbarService.showError(context, 'Erro ao analisar: $e');
      }
    }
  }

  Future<void> _handleExecuteRestore() async {
    if (_importPlan == null || !_importPlan!.canExecute) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Restauração'),
        content: Text(
          'Deseja restaurar ${_importPlan!.willWriteCount} registros e ${_importPlan!.attachmentsToUploadCount} anexos?\n\n'
          'Os dados idênticos já existentes serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar Agora'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isRestoring = true;
      _restoreProgressStatus = 'Preparando restauração...';
      _restoreProgressValue = 0.0;
    });

    try {
      final sessionContext = SessionContext(
        userId: user.uid,
        sessionGeneration: 1,
      );
      final rawStorage = FirestoreRawStorage();
      final restoreService = RestoreService(
        rawReader: rawStorage,
        rawWriter: rawStorage,
        sessionContext: sessionContext,
        encryptionService: EncryptionService(),
        driveService: DriveService(),
      );

      final result = await restoreService.executeRestore(
        plan: _importPlan!,
        backupBytes: _selectedRestoreBytes!,
        password: _restorePassController.text,
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _restoreProgressStatus = status;
              _restoreProgressValue = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isRestoring = false;
        });

        if (result.isSuccess && result.data != null) {
          final summary = result.data!;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Restauração Concluída'),
              content: Text(
                'Criados: ${summary.createdCount}\n'
                'Substituídos: ${summary.replacedCount}\n'
                'Ignorados (idênticos): ${summary.skippedCount}\n'
                'Anexos enviados: ${summary.uploadedAttachmentsCount}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          SnackbarService.showError(
            context,
            result.safeError ?? 'Restauração não foi concluída totalmente.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
        SnackbarService.showError(context, 'Erro durante restauração: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração (.kbudget)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.backup_outlined), text: 'Criar Backup'),
            Tab(icon: Icon(Icons.settings_backup_restore), text: 'Restaurar Dados'),
          ],
        ),
      ),
      body: ResponsiveCenter(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCreateBackupTab(),
            _buildRestoreBackupTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBackupTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.radiusM),
          ),
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Colors.blueAccent),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'O formato .kbudget é criptografado com AES-256-GCM e chave derivada por senha (PBKDF2). '
                    'A senha escolhida não pode ser recuperada caso esquecida.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Módulos Incluídos no Pacote',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._selectedModules.keys.map((key) {
          return CheckboxListTile(
            title: Text(_getModuleLabel(key)),
            value: _selectedModules[key],
            onChanged: _isCreatingBackup
                ? null
                : (val) {
                    setState(() {
                      _selectedModules[key] = val ?? false;
                    });
                  },
          );
        }),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Proteção por Senha',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _createPassController,
          label: 'Senha de Criptografia do Backup',
          hint: 'Mínimo 6 caracteres',
          obscureText: _obscureCreatePass,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureCreatePass ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscureCreatePass = !_obscureCreatePass;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _createConfirmPassController,
          label: 'Confirmar Senha do Backup',
          obscureText: _obscureCreatePass,
          prefixIcon: Icons.lock_reset,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isCreatingBackup) ...[
          LinearProgressIndicator(value: _createProgressValue),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _createProgressStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppButton(
          label: 'Gerar Pacote de Backup (.kbudget)',
          icon: Icons.lock,
          isLoading: _isCreatingBackup,
          isFullWidth: true,
          onPressed: _isCreatingBackup ? null : _handleCreateBackup,
        ),
        if (_lastBackupResult != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorders.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Backup Gerado com Sucesso',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('ID: ${_lastBackupResult!.manifest.backupId}'),
                  Text(
                    'Tamanho: ${(_lastBackupResult!.envelopeBytes.length / 1024).toStringAsFixed(1)} KB',
                  ),
                  Text(
                    'Completude: ${_lastBackupResult!.completeness.isComplete ? "Completo" : "Parcial com avisos"}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar'),
                          onPressed: _shareBackupFile,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Salvar no Drive'),
                          onPressed: _uploadBackupToDrive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestoreBackupTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.radiusM),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arquivo Selecionado',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _selectedRestoreFileName ?? 'Nenhum arquivo selecionado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedRestoreFileName != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Escolher Arquivo .kbudget'),
                  onPressed: _pickRestoreFile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _restorePassController,
          label: 'Senha de Descriptografia do Backup',
          obscureText: _obscureRestorePass,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRestorePass ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscureRestorePass = !_obscureRestorePass;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Analisar Arquivo (Prévia Segura)',
          icon: Icons.preview,
          isLoading: _isPreviewing,
          isFullWidth: true,
          onPressed: _isPreviewing || _selectedRestoreBytes == null
              ? null
              : _handlePreviewRestore,
        ),
        if (_importPlan != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildPlanPreviewCard(_importPlan!),
        ],
      ],
    );
  }

  Widget _buildPlanPreviewCard(ImportPlan plan) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorders.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  plan.isUidMatched ? Icons.verified_user : Icons.error_outline,
                  color: plan.isUidMatched ? Colors.green : Colors.red,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    plan.isUidMatched
                        ? 'Conta compatível com o backup'
                        : 'Backup pertence a outra conta (${plan.originUid})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: plan.isUidMatched ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.add_circle, color: Colors.green, size: 18),
                  label: Text('Criar: ${plan.createCount}'),
                ),
                Chip(
                  avatar: const Icon(Icons.check, color: Colors.grey, size: 18),
                  label: Text('Idênticos: ${plan.skipCount}'),
                ),
                Chip(
                  avatar: const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  label: Text('Conflitos: ${plan.conflictCount}'),
                ),
                Chip(
                  avatar: const Icon(Icons.attach_file, color: Colors.blue, size: 18),
                  label: Text('Anexos: ${plan.attachmentsToUploadCount}'),
                ),
              ],
            ),
            if (plan.conflictCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Política de Resolução de Conflitos:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<ConflictResolution>(
                segments: const [
                  ButtonSegment(
                    value: ConflictResolution.keepTarget,
                    label: Text('Manter Atual (Padrão)'),
                    icon: Icon(Icons.shield_outlined),
                  ),
                  ButtonSegment(
                    value: ConflictResolution.replaceWithSource,
                    label: Text('Substituir pelo Backup'),
                    icon: Icon(Icons.file_download),
                  ),
                ],
                selected: {
                  plan.items
                      .firstWhere((i) => i.action == ImportAction.conflict)
                      .resolution,
                },
                onSelectionChanged: (newSelection) {
                  setState(() {
                    plan.setBulkConflictResolution(newSelection.first);
                  });
                },
              ),
            ],
            if (plan.orphans.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ExpansionTile(
                title: Text(
                  'Vínculos Órfãos Detectados (${plan.orphans.length})',
                  style: const TextStyle(fontSize: 13, color: Colors.orange),
                ),
                children: plan.orphans
                    .map((o) => ListTile(
                          dense: true,
                          title: Text(o, style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_isRestoring) ...[
              LinearProgressIndicator(value: _restoreProgressValue),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _restoreProgressStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: 'Confirmar e Restaurar Dados',
              icon: Icons.restore,
              isLoading: _isRestoring,
              isFullWidth: true,
              onPressed: !plan.canExecute || _isRestoring
                  ? null
                  : _handleExecuteRestore,
            ),
          ],
        ),
      ),
    );
  }
}
