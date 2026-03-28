import 'dart:async';

import 'package:flutter/material.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/credentials/widgets/credential_list_tile.dart';
import 'package:key_budget/features/credentials/widgets/folder_list_tile.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();
  final EncryptionService _encryptionService = EncryptionService();
  final CsvService _csvService = CsvService();
  final PdfService _pdfService = PdfService();
  final DataImportService _dataImportService = DataImportService();

  List<Credential> _allCredentials = [];
  List<Folder> _allFolders = [];
  List<dynamic> _currentDisplayItems = [];

  bool _isLoading = false;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  String _searchQuery = '';

  StreamSubscription? _credentialsSubscription;
  StreamSubscription? _foldersSubscription;
  bool _isListening = false;

  String? _currentFolderId;

  GlobalKey<SliverAnimatedListState>? listKey;

  List<Credential> get allCredentials => _allCredentials;

  List<Folder> get allFolders => _allFolders;

  List<dynamic> get currentDisplayItems => _currentDisplayItems;

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
    var text = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    const withDia = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const withoutDia = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    return text;
  }

  void setSearchQuery(String query) {
    _searchQuery = _sanitize(query);
    _updateDisplayList();
  }

  void listenToCredentials(String userId) {
    if (_isListening) return;

    _setLoading(true);
    _credentialsSubscription?.cancel();
    _foldersSubscription?.cancel();

    _foldersSubscription =
        _repository.getFoldersStreamForUser(userId).listen((folders) {
      _allFolders = folders;
      _updateDisplayList();
    });

    _credentialsSubscription = _repository
        .getCredentialsStreamForUser(userId)
        .listen((newCredentials) {
      _allCredentials = newCredentials;
      _updateDisplayList();
      if (_isLoading) _setLoading(false);
    });

    _isListening = true;
  }

  void _updateDisplayList() {
    final oldList = List<dynamic>.from(_currentDisplayItems);
    final List<dynamic> newList = [];

    if (_currentFolderId == null) {
      newList.addAll(_allFolders);
      newList.addAll(_allCredentials.where((c) => c.folderId == null));
    } else {
      newList
          .addAll(_allCredentials.where((c) => c.folderId == _currentFolderId));
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

    for (var i = oldList.length - 1; i >= 0; i--) {
      final oldItem = oldList[i];
      bool existsInNew = false;

      if (oldItem is Folder) {
        existsInNew = newList
            .any((newItem) => newItem is Folder && newItem.id == oldItem.id);
      } else if (oldItem is Credential) {
        existsInNew = newList.any(
            (newItem) => newItem is Credential && newItem.id == oldItem.id);
      }

      if (!existsInNew) {
        final indexToRemove = _currentDisplayItems.indexOf(oldItem);
        if (indexToRemove != -1) {
          _currentDisplayItems.removeAt(indexToRemove);
          listKey?.currentState?.removeItem(
            indexToRemove,
            (context, animation) => AnimatedListItem(
              animation: animation,
              child: oldItem is Folder
                  ? FolderListTile(
                      folder: oldItem, onTap: () {}, onDelete: () {})
                  : CredentialListTile(credential: oldItem as Credential),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }

    for (var i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      int oldIndex = -1;

      if (newItem is Folder) {
        oldIndex = _currentDisplayItems
            .indexWhere((item) => item is Folder && item.id == newItem.id);
      } else if (newItem is Credential) {
        oldIndex = _currentDisplayItems
            .indexWhere((item) => item is Credential && item.id == newItem.id);
      }

      if (oldIndex == -1) {
        _currentDisplayItems.insert(i, newItem);
        listKey?.currentState
            ?.insertItem(i, duration: const Duration(milliseconds: 300));
      } else {
        if (_currentDisplayItems[oldIndex] != newItem) {
          _currentDisplayItems[oldIndex] = newItem;
          notifyListeners();
        }

        if (oldIndex != i) {
          final item = _currentDisplayItems.removeAt(oldIndex);
          _currentDisplayItems.insert(i, item);

          if (oldIndex < _currentDisplayItems.length) {
            notifyListeners();
          }
        }
      }
    }

    if (_currentDisplayItems.length != newList.length) {
      _currentDisplayItems = List.from(newList);
      notifyListeners();
    }
  }

  void enterFolder(String folderId) {
    if (listKey?.currentState != null) {
      for (int i = _currentDisplayItems.length - 1; i >= 0; i--) {
        listKey!.currentState!.removeItem(
            i, (context, animation) => const SizedBox(),
            duration: Duration.zero);
      }
    }
    _currentDisplayItems.clear();
    _currentFolderId = folderId;
    _updateDisplayList();
    notifyListeners();
  }

  void exitFolder() {
    if (listKey?.currentState != null) {
      for (int i = _currentDisplayItems.length - 1; i >= 0; i--) {
        listKey!.currentState!.removeItem(
            i, (context, animation) => const SizedBox(),
            duration: Duration.zero);
      }
    }
    _currentDisplayItems.clear();
    _currentFolderId = null;
    _updateDisplayList();
    notifyListeners();
  }

  Future<void> createFolder(String userId, String name) async {
    final folder = Folder(
      name: name,
      createdAt: DateTime.now(),
    );
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
    final encryptedPassword = _encryptionService.encryptData(plainPassword);
    final newCredential = Credential(
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
    String passwordToSave = originalCredential.encryptedPassword;
    if (newPlainPassword != null && newPlainPassword.isNotEmpty) {
      final decryptedOriginal =
          decryptPassword(originalCredential.encryptedPassword);
      if (newPlainPassword != decryptedOriginal) {
        passwordToSave = _encryptionService.encryptData(newPlainPassword);
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
    await _repository.deleteCredential(userId, credentialId);
  }

  Future<bool> exportCredentialsToCsv(BuildContext context) async {
    _setExportingCsv(true);
    try {
      return await _csvService.exportCredentials(
          context, _allCredentials, decryptPassword);
    } finally {
      _setExportingCsv(false);
    }
  }

  Future<void> exportCredentialsToPdf(BuildContext context) async {
    _setExportingPdf(true);
    try {
      await _pdfService.exportCredentialsPdf(context, this);
    } finally {
      _setExportingPdf(false);
    }
  }

  Future<int> importCredentialsFromCsv(String userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;
    int count = 0;
    for (var row in data) {
      final plainPassword = row['password']?.toString() ?? '';
      if (plainPassword.isEmpty) continue;
      final newCredential = Credential(
        location: row['location']?.toString() ?? 'N/A',
        login: row['login']?.toString() ?? 'N/A',
        encryptedPassword: _encryptionService.encryptData(plainPassword),
        email: row['email']?.toString(),
        phoneNumber: row['phone_number']?.toString(),
        notes: row['notes']?.toString(),
        folderId: _currentFolderId,
      );
      await _repository.addCredential(userId, newCredential);
      count++;
    }
    return count;
  }

  Future<int> importCredentialsFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importCredentialsFromJson(userId);
    _setLoading(false);
    return count;
  }

  String decryptPassword(String encryptedPassword) {
    return _encryptionService.decryptData(encryptedPassword);
  }

  void clearData() {
    _credentialsSubscription?.cancel();
    _foldersSubscription?.cancel();
    _allCredentials = [];
    _allFolders = [];
    _currentDisplayItems = [];
    _isListening = false;
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
