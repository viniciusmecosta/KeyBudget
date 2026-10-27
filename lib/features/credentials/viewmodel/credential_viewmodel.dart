import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/core/search/search_normalizer.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/security/vault_session.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/features/credentials/application/credential_transfer_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';
import 'package:key_budget/features/trash/repository/trash_repository.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository;
  final EncryptionService? encryptionService;
  final EncryptionService Function()? encryptionResolver;
  final CsvService _csvService;
  final PdfService _pdfService;
  final DataImportService _dataImportService;
  final ImportService _importService;
  final TrashRepository _trashRepository;
  late final CredentialTransferService _transferService;

  CredentialViewModel({
    CredentialRepository? repository,
    this.encryptionService,
    this.encryptionResolver,
    CsvService? csvService,
    PdfService? pdfService,
    DataImportService? dataImportService,
    ImportService? importService,
    TrashRepository? trashRepository,
  }) : _repository = repository ?? CredentialRepository(),
       _csvService = csvService ?? CsvService(),
       _pdfService = pdfService ?? PdfService(),
       _dataImportService =
           dataImportService ??
           DataImportService(
             encryptionService: encryptionService,
             encryptionResolver: encryptionResolver,
           ),
       _trashRepository = trashRepository ?? TrashRepository(),
       _importService =
           importService ??
           ImportService(
             expenseRepository: ExpenseRepository(),
             credentialRepository: repository ?? CredentialRepository(),
             recurringRepository: RecurringExpenseRepository(),
             encryptionService: encryptionService,
             encryptionResolver: encryptionResolver,
           ) {
    _transferService = CredentialTransferService(
      csvService: _csvService,
      pdfService: _pdfService,
      dataImportService: _dataImportService,
      importService: _importService,
    );
  }

  EncryptionService get _activeEncryptionService =>
      encryptionService ?? encryptionResolver?.call() ?? EncryptionService();

  List<Credential> _allCredentials = [];
  List<Folder> _allFolders = [];
  List<dynamic> _currentDisplayItems = [];

  bool _isLoading = false;
  String? _loadErrorMessage;
  String? _listeningUserId;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  String _searchQuery = '';

  StreamSubscription? _credentialsSubscription;
  StreamSubscription? _foldersSubscription;
  bool _isListening = false;

  String? _currentFolderId;

  List<Credential> get allCredentials => _allCredentials;

  List<Folder> get allFolders => _allFolders;

  List<dynamic> get currentDisplayItems =>
      List.unmodifiable(_currentDisplayItems);

  String? get currentFolderId => _currentFolderId;

  String get searchQuery => _searchQuery;

  Folder? get currentFolder {
    if (_currentFolderId == null) return null;
    try {
      return _allFolders.firstWhere((f) => f.id == _currentFolderId);
    } catch (_) {
      return null;
    }
  }

  List<String> get userCredentialLogos => _allCredentials
      .map((cred) => cred.logoPath)
      .whereType<String>()
      .where((path) => path.isNotEmpty)
      .toSet()
      .toList();

  bool get isLoading => _isLoading;
  String? get loadErrorMessage => _loadErrorMessage;

  bool get isExportingCsv => _isExportingCsv;

  bool get isExportingPdf => _isExportingPdf;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setExportingCsv(bool value) {
    if (_isExportingCsv != value) {
      _isExportingCsv = value;
      notifyListeners();
    }
  }

  void _setExportingPdf(bool value) {
    if (_isExportingPdf != value) {
      _isExportingPdf = value;
      notifyListeners();
    }
  }

  String _sanitize(String input) {
    return SearchNormalizer.normalize(input);
  }

  void setSearchQuery(String query) {
    _searchQuery = _sanitize(query);
    _updateDisplayList();
  }

  void listenToCredentials(String userId) {
    if (_isListening && _listeningUserId == userId) return;

    if (_listeningUserId != userId) {
      _allCredentials = [];
      _allFolders = [];
      _currentDisplayItems = [];
      _currentFolderId = null;
      _searchQuery = '';
    }
    _listeningUserId = userId;
    _loadErrorMessage = null;

    _setLoading(true);
    _credentialsSubscription?.cancel();
    _foldersSubscription?.cancel();

    _foldersSubscription = _repository.getFoldersStreamForUser(userId).listen((
      folders,
    ) {
      if (_listeningUserId != userId) return;
      _allFolders = folders;
      _updateDisplayList();
    }, onError: (Object error) => _handleLoadError(userId));

    _credentialsSubscription = _repository
        .getCredentialsStreamForUser(userId)
        .listen((newCredentials) {
          if (_listeningUserId != userId) return;
          _allCredentials = newCredentials;
          _loadErrorMessage = null;
          _updateDisplayList();
          if (_isLoading) _setLoading(false);
        }, onError: (Object error) => _handleLoadError(userId));

    _isListening = true;
  }

  void _handleLoadError(String userId) {
    if (_listeningUserId != userId) return;
    _loadErrorMessage =
        'Não foi possível carregar o cofre. Confira sua conexão e tente novamente.';
    _isListening = false;
    _setLoading(false);
    notifyListeners();
  }

  void retryListenToCredentials(String userId) {
    _isListening = false;
    listenToCredentials(userId);
  }

  void _updateDisplayList() {
    final List<dynamic> newList = [];

    if (_currentFolderId == null) {
      newList.addAll(_allFolders);
      newList.addAll(_allCredentials.where((c) => c.folderId == null));
    } else {
      newList.addAll(
        _allCredentials.where((c) => c.folderId == _currentFolderId),
      );
    }

    if (_searchQuery.isNotEmpty) {
      newList.retainWhere((item) {
        if (item is Folder) {
          return _sanitize(item.name).contains(_searchQuery);
        } else if (item is Credential) {
          return _sanitize(item.location).contains(_searchQuery) ||
              _sanitize(item.login).contains(_searchQuery) ||
              (item.notes != null &&
                  _sanitize(item.notes!).contains(_searchQuery));
        }
        return false;
      });
    }

    newList.sort((a, b) {
      if (a is Folder && b is Credential) return -1;
      if (a is Credential && b is Folder) return 1;
      if (a is Folder && b is Folder) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (a is Credential && b is Credential) {
        return a.location.toLowerCase().compareTo(b.location.toLowerCase());
      }
      return 0;
    });

    _currentDisplayItems = newList;
    notifyListeners();
  }

  void enterFolder(String folderId) {
    _currentFolderId = folderId;
    notifyListeners();
    _updateDisplayList();
  }

  void exitFolder() {
    _currentFolderId = null;
    notifyListeners();
    _updateDisplayList();
  }

  Future<void> createFolder(String userId, String name, {String? color}) async {
    final folder = Folder(name: name, color: color, createdAt: DateTime.now());
    await _repository.addFolder(userId, folder);
  }

  Future<void> deleteFolder(String userId, String folderId) async {
    await _repository.deleteFolder(userId, folderId);
  }

  Future<void> addCredential({
    required String userId,
    required String location,
    required String login,
    required String plainPassword,
    String? email,
    String? phoneNumber,
    String? notes,
    String? logoPath,
    String? folderId,
  }) async {
    final id = _repository.reserveCredentialId(userId);
    final encryptedPassword = _activeEncryptionService.encryptData(
      plainPassword,
      recordId: id,
    );
    final newCredential = Credential(
      id: id,
      location: location,
      login: login,
      encryptedPassword: encryptedPassword,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath,
      folderId: folderId ?? _currentFolderId,
    );

    await _repository.addCredential(userId, newCredential);
  }

  Future<void> updateCredential({
    required String userId,
    required Credential originalCredential,
    required String location,
    required String login,
    String? newPlainPassword,
    String? email,
    String? phoneNumber,
    String? notes,
    String? logoPath,
    String? folderId,
  }) async {
    final encryption = _activeEncryptionService;
    final decryptedOriginal = encryption.decryptData(
      originalCredential.encryptedPassword,
      recordId: originalCredential.id,
    );
    String passwordToSave = originalCredential.encryptedPassword;
    if (newPlainPassword != null && newPlainPassword.isNotEmpty) {
      if (newPlainPassword != decryptedOriginal) {
        passwordToSave = encryption.encryptData(
          newPlainPassword,
          recordId: originalCredential.id,
        );
      }
    }
    final updatedCredential = Credential(
      id: originalCredential.id,
      location: location,
      login: login,
      encryptedPassword: passwordToSave,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath,
      folderId: folderId,
    );

    await _repository.updateCredential(userId, updatedCredential);
  }

  Future<void> deleteCredential(String userId, String credentialId) async {
    final credential = _allCredentials
        .where((item) => item.id == credentialId)
        .firstOrNull;
    await _trashRepository.move(
      userId,
      collection: 'credentials',
      ids: [credentialId],
      title: credential?.location ?? 'Credencial',
    );
  }

  Future<void> restoreCredential(String userId, Credential credential) async {
    await _repository.restoreCredential(userId, credential);
  }

  Future<bool> exportCredentialsToCsv(BuildContext context) async {
    _setExportingCsv(true);
    try {
      return await _transferService.exportCsv(
        context,
        _allCredentials,
        (credential) => decryptPassword(
          credential.encryptedPassword,
          recordId: credential.id,
        ),
      );
    } finally {
      _setExportingCsv(false);
    }
  }

  Future<void> exportCredentialsToPdf(BuildContext context) async {
    _setExportingPdf(true);
    try {
      await _transferService.exportPdf(
        context,
        _allCredentials,
        (credential) => decryptPassword(
          credential.encryptedPassword,
          recordId: credential.id,
        ),
      );
    } finally {
      _setExportingPdf(false);
    }
  }

  ImportService get importService => _importService;

  Future<int> importCredentialsFromCsv(
    String userId, {
    BuildContext? context,
    String? rawCsvContent,
    String? fileName,
  }) async {
    return _transferService.importCsv(
      userId,
      _allCredentials,
      _currentFolderId,
      context: context,
      rawCsvContent: rawCsvContent,
      fileName: fileName,
    );
  }

  Future<int> importCredentialsFromJson(String userId) async {
    _setLoading(true);
    final count = await _transferService.importLegacyJson(userId);
    _setLoading(false);
    return count;
  }

  String decryptPassword(String encryptedPassword, {String? recordId}) {
    return _activeEncryptionService.decryptData(
      encryptedPassword,
      recordId: recordId,
    );
  }

  void clearData() {
    _credentialsSubscription?.cancel();
    _foldersSubscription?.cancel();
    _allCredentials = [];
    _allFolders = [];
    _currentDisplayItems = [];
    _isListening = false;
    _listeningUserId = null;
    _loadErrorMessage = null;
    _isLoading = false;
    _currentFolderId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _credentialsSubscription?.cancel();
    _foldersSubscription?.cancel();
    super.dispose();
  }
}

final credentialViewModelProvider = ChangeNotifierProvider<CredentialViewModel>(
  (ref) => CredentialViewModel(
    repository: ref.read(credentialRepositoryProvider),
    encryptionResolver: () => ref.read(vaultSessionProvider).encryption,
    importService: ref.read(importServiceProvider),
  ),
);
