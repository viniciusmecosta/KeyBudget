import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:key_budget/features/documents/widgets/document_list_tile.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentViewModel extends ChangeNotifier {
  static const maxAttachmentBytes = 25 * 1024 * 1024;
  static const allowedAttachmentTypes = {'jpg', 'png', 'webp', 'pdf'};

  static bool matchesAttachmentFormat(List<int> header, String type) {
    bool startsWith(List<int> signature) =>
        header.length >= signature.length &&
        List.generate(
          signature.length,
          (index) => index,
        ).every((index) => header[index] == signature[index]);

    switch (type.toLowerCase()) {
      case 'jpg':
        return startsWith([0xff, 0xd8, 0xff]);
      case 'png':
        return startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
      case 'webp':
        return header.length >= 12 &&
            startsWith([0x52, 0x49, 0x46, 0x46]) &&
            header[8] == 0x57 &&
            header[9] == 0x45 &&
            header[10] == 0x42 &&
            header[11] == 0x50;
      case 'pdf':
        return startsWith([0x25, 0x50, 0x44, 0x46, 0x2d]);
      default:
        return false;
    }
  }

  static Future<bool> _isValidAttachmentFile(File file, String type) async {
    final header = await file.openRead(0, 16).expand((chunk) => chunk).toList();
    return matchesAttachmentFormat(header, type);
  }

  final DocumentRepository _repository;
  final DriveService _driveService;
  final Future<void> Function(String) _clearLocalCache;

  DocumentViewModel({
    DocumentRepository? repository,
    DriveService? driveService,
    Future<void> Function(String)? clearLocalCache,
  }) : _repository = repository ?? DocumentRepository(),
       _driveService = driveService ?? DriveService(),
       _clearLocalCache = clearLocalCache ?? _deleteLocalAttachmentCache;

  static Future<void> _deleteLocalAttachmentCache(String driveId) async {
    final directory = await getApplicationDocumentsDirectory();
    await for (final entry in directory.list()) {
      if (entry is File && p.basename(entry.path).startsWith('$driveId-')) {
        await entry.delete();
      }
    }
  }

  StreamSubscription? _documentsSubscription;
  bool _isListening = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Document> _documents = [];
  List<Document> _currentDisplayItems = [];
  bool _isUploading = false;
  double? _uploadProgress;
  String _searchQuery = '';

  GlobalKey<SliverAnimatedListState>? _listKey;

  void setListKey(GlobalKey<SliverAnimatedListState> key) {
    _listKey = key;
  }

  bool get isUploading => _isUploading;

  double? get uploadProgress => _uploadProgress;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  List<Document> get currentDisplayItems => _currentDisplayItems;
  bool get hasDocuments => _documents.isNotEmpty;

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
    _updateDisplayList(animate: true);
  }

  void listenToDocuments(String userId) {
    if (_isListening) return;
    _setLoading(true);
    _documentsSubscription?.cancel();
    _documentsSubscription = _repository
        .getDocumentsStream(userId)
        .listen(
          (newDocs) async {
            try {
              final processedNewDocs = await _processDocuments(newDocs, userId);
              _documents = processedNewDocs;
              _setErrorMessage(null);
              _updateDisplayList(animate: true);
              unawaited(retryPendingAttachmentCleanup(userId));
            } catch (_) {
              _setErrorMessage('Erro ao carregar os documentos.');
            } finally {
              _setLoading(false);
            }
          },
          onError: (error) {
            _setErrorMessage('Erro ao carregar os documentos.');
            _isListening = false;
            _setLoading(false);
          },
        );
    _isListening = true;
  }

  void retryListenToDocuments(String userId) {
    _isListening = false;
    listenToDocuments(userId);
  }

  void _updateDisplayList({bool animate = true}) {
    final oldList = List<Document>.from(_currentDisplayItems);
    final List<Document> newList = List.from(_documents);

    if (_searchQuery.isNotEmpty) {
      newList.retainWhere(
        (doc) => _sanitize(doc.documentName).contains(_searchQuery),
      );
    }

    newList.sort(
      (a, b) =>
          a.documentName.toLowerCase().compareTo(b.documentName.toLowerCase()),
    );

    if (!animate || _listKey?.currentState == null) {
      _currentDisplayItems = List.from(newList);
      notifyListeners();
      return;
    }

    for (var i = oldList.length - 1; i >= 0; i--) {
      final oldItem = oldList[i];
      if (!newList.any((newItem) => newItem.id == oldItem.id)) {
        final indexToRemove = _currentDisplayItems.indexWhere(
          (item) => item.id == oldItem.id,
        );
        if (indexToRemove != -1) {
          final removedDoc = _currentDisplayItems.removeAt(indexToRemove);
          _listKey?.currentState?.removeItem(
            indexToRemove,
            (context, animation) => AnimatedListItem(
              animation: animation,
              child: DocumentListTile(
                key: ValueKey(removedDoc.id),
                doc: removedDoc,
              ),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }

    for (var i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      final oldIndex = _currentDisplayItems.indexWhere(
        (item) => item.id == newItem.id,
      );

      if (oldIndex == -1) {
        _currentDisplayItems.insert(i, newItem);
        _listKey?.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 300),
        );
      } else {
        if (_currentDisplayItems[oldIndex] != newItem) {
          _currentDisplayItems[oldIndex] = newItem;
          notifyListeners();
        }
        if (oldIndex != i) {
          final item = _currentDisplayItems.removeAt(oldIndex);
          _currentDisplayItems.insert(i, item);
          notifyListeners();
        }
      }
    }

    if (_currentDisplayItems.length != newList.length) {
      _currentDisplayItems = List.from(newList);
      notifyListeners();
    }
  }

  Future<void> forceRefresh(String userId) async {
    _setLoading(true);
    try {
      final docs = await _repository.getDocumentsForUser(userId);
      final processedDocs = await _processDocuments(docs, userId);
      _documents = processedDocs;
      _setErrorMessage(null);
      _updateDisplayList(animate: true);
    } catch (_) {
      _setErrorMessage('Não foi possível atualizar os documentos.');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Document>> _processDocuments(
    List<Document> docs,
    String userId,
  ) async {
    final Map<String, List<Document>> versionsMap = {};
    for (var doc in docs) {
      final key = doc.originalDocumentId ?? doc.id!;
      versionsMap.putIfAbsent(key, () => []).add(doc);
    }

    final List<Document> result = [];
    versionsMap.forEach((key, versions) {
      versions.sort((a, b) {
        if (a.issueDate == null && b.issueDate == null) return 0;
        if (a.issueDate == null) return 1;
        if (b.issueDate == null) return -1;
        return b.issueDate!.compareTo(a.issueDate!);
      });

      final mainVersion = versions.firstWhere(
        (v) => v.isPrincipal,
        orElse: () => versions.first,
      );
      final otherVersions = versions
          .where((v) => v.id != mainVersion.id)
          .toList();
      result.add(mainVersion.copyWith(versions: otherVersions));
    });

    result.sort(
      (a, b) =>
          a.documentName.toLowerCase().compareTo(b.documentName.toLowerCase()),
    );
    return result;
  }

  Future<String?> addDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      final newId = await _repository.addDocument(userId, document);
      return newId;
    } catch (e) {
      _setErrorMessage('Não foi possível adicionar o documento.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDocument(
    String userId,
    Document document,
    Document originalDocument,
  ) async {
    _setLoading(true);
    try {
      final originalAttachments = originalDocument.attachments;
      final currentAttachments = document.attachments;
      final attachmentsToDelete = originalAttachments
          .where(
            (att) =>
                !currentAttachments.any((cAtt) => cAtt.driveId == att.driveId),
          )
          .toList();
      await _repository.updateDocumentWithCleanup(
        userId,
        document,
        attachmentsToDelete
            .map((attachment) => attachment.driveId)
            .toSet()
            .toList(),
      );
      await retryPendingAttachmentCleanup(userId);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível atualizar o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> retryPendingAttachmentCleanup(String userId) async {
    try {
      final pending = await _repository.getPendingAttachmentCleanup(userId);
      if (pending.isEmpty) return;
      final referenced = await _repository.getReferencedAttachmentIds(userId);
      for (final driveId in pending) {
        try {
          if (referenced.contains(driveId)) {
            await _repository.acknowledgeAttachmentCleanup(userId, driveId);
            continue;
          }
          final deleted = await _driveService.deleteFile(driveId);
          if (deleted) {
            await _clearLocalCache(driveId);
            await _repository.acknowledgeAttachmentCleanup(userId, driveId);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<bool> deleteDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      final rootId = document.originalDocumentId ?? document.id!;
      final family = await _repository.getDocumentFamily(userId, rootId);
      if (family.isEmpty) {
        _setErrorMessage('O documento não foi encontrado. Atualize a lista.');
        return false;
      }
      await _repository.deleteDocumentsWithCleanup(
        userId,
        family.map((version) => version.id!).toList(),
        {
          for (final version in family)
            for (final attachment in version.attachments) attachment.driveId,
        }.toList(),
      );
      await retryPendingAttachmentCleanup(userId);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível excluir o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteVersion(String userId, Document version) async {
    _setLoading(true);
    try {
      final rootId = version.originalDocumentId;
      if (rootId == null || version.id == null) {
        _setErrorMessage('Esta versão não pode ser excluída separadamente.');
        return false;
      }
      final family = await _repository.getDocumentFamily(userId, rootId);
      final current = family.where((item) => item.id == version.id).firstOrNull;
      if (current == null) {
        _setErrorMessage('A versão não foi encontrada. Atualize a lista.');
        return false;
      }
      if (current.isPrincipal && family.length > 1) {
        _setErrorMessage(
          'Defina outra versão como principal antes de excluir esta versão.',
        );
        return false;
      }
      await _repository.deleteDocumentsWithCleanup(
        userId,
        [current.id!],
        {
          for (final attachment in current.attachments) attachment.driveId,
        }.toList(),
      );
      await retryPendingAttachmentCleanup(userId);
      return true;
    } catch (_) {
      _setErrorMessage(
        'Não foi possível excluir esta versão. Tente novamente.',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setAsPrincipal(
    String userId,
    Document newPrincipal,
    List<Document> allVersions,
  ) async {
    _setLoading(true);
    try {
      final batch = _repository.firestore.batch();
      for (var doc in allVersions) {
        final docRef = _repository.getDocumentsCollection(userId).doc(doc.id);
        batch.update(docRef, {'isPrincipal': doc.id == newPrincipal.id});
      }
      await batch.commit();
      await forceRefresh(userId);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível definir como principal.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Attachment?> pickAndUploadFile() async {
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp', 'pdf'],
      );

      if (result != null) {
        final filePath = result.files.single.path;
        if (filePath == null) {
          _setErrorMessage('Não foi possível acessar o arquivo selecionado.');
          return null;
        }
        final file = File(filePath);
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        if (!allowedAttachmentTypes.contains(extension)) {
          _setErrorMessage('Selecione um arquivo JPG, PNG, WEBP ou PDF.');
          return null;
        }
        if (await file.length() > maxAttachmentBytes) {
          _setErrorMessage('O anexo deve ter no máximo 25 MB.');
          return null;
        }
        if (!await _isValidAttachmentFile(file, extension)) {
          _setErrorMessage(
            'O conteúdo do arquivo não corresponde ao formato selecionado.',
          );
          return null;
        }

        final driveFile = await _driveService.uploadFile(file, (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        });

        if (driveFile == null || driveFile.id == null) {
          _setErrorMessage(
            'Falha ao fazer upload do arquivo para o Google Drive.',
          );
          return null;
        }

        return Attachment(
          name: result.files.single.name,
          type: extension,
          driveId: driveFile.id!,
        );
      }
      return null;
    } on DriveAuthorizationCancelled {
      return null;
    } catch (e) {
      _setErrorMessage('Erro ao selecionar ou processar o arquivo.');
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = null;
      notifyListeners();
    }
  }

  Future<File> _getLocalFile(Attachment attachment) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      '${p.basename(attachment.driveId)}-${p.basename(attachment.name)}',
    );
    return File(filePath);
  }

  Future<File?> getAttachmentFile(Attachment attachment) async {
    try {
      if (!allowedAttachmentTypes.contains(attachment.type.toLowerCase())) {
        _setErrorMessage('Este formato de anexo não é permitido.');
        return null;
      }
      final file = await _getLocalFile(attachment);

      if (await file.exists()) {
        if (await file.length() > maxAttachmentBytes) {
          await file.delete();
          _setErrorMessage('O anexo excede o limite de 25 MB.');
          return null;
        }
        if (!await _isValidAttachmentFile(file, attachment.type)) {
          await file.delete();
          _setErrorMessage('O anexo possui formato inválido.');
          return null;
        }
        return file;
      } else {
        final downloaded = await _driveService.downloadToFileLimited(
          attachment.driveId,
          file,
          maxBytes: maxAttachmentBytes,
        );
        if (!downloaded) {
          _setErrorMessage('Não foi possível baixar o anexo do Google Drive.');
          return null;
        }
        if (!await _isValidAttachmentFile(file, attachment.type)) {
          await file.delete();
          _setErrorMessage('O anexo possui formato inválido.');
          return null;
        }
        return file;
      }
    } on DriveAuthorizationCancelled {
      return null;
    } on DriveFileTooLargeException {
      _setErrorMessage('O anexo excede o limite de 25 MB.');
      return null;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro ao obter o anexo.');
      return null;
    }
  }

  Future<void> deleteAttachmentFile(Attachment attachment) async {
    final file = await _getLocalFile(attachment);
    if (await file.exists()) {
      await file.delete();
    }
    await _driveService.deleteFile(attachment.driveId);
  }

  Future<void> openFile(Attachment attachment) async {
    final file = await getAttachmentFile(attachment);
    if (file != null) {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        _setErrorMessage('Não foi possível abrir o arquivo: ${result.message}');
      }
    }
  }

  Future<void> shareAttachment(Attachment attachment) async {
    final file = await getAttachmentFile(attachment);
    if (file != null) {
      final params = ShareParams(
        files: [XFile(file.path)],
        text: attachment.name,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      await SharePlus.instance.share(params);
    } else {
      _setErrorMessage('Não foi possível obter o arquivo para compartilhar.');
    }
  }

  Future<String?> getAttachmentAsBase64(Attachment attachment) async {
    final file = await getAttachmentFile(attachment);
    if (file != null) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
  }

  void clearData() {
    _documentsSubscription?.cancel();
    _documents = [];
    _currentDisplayItems = [];
    _isListening = false;
    notifyListeners();
  }
}

final documentViewModelProvider = ChangeNotifierProvider<DocumentViewModel>(
  (ref) => DocumentViewModel(),
);
