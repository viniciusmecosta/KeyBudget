import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final DocumentRepository _repository = DocumentRepository();
  final DriveService _driveService = DriveService();
  StreamSubscription? _documentsSubscription;
  bool _isListening = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Document> _documents = [];
  List<Document> _currentDisplayItems = [];
  bool _isUploading = false;
  double? _uploadProgress;
  String _searchQuery = '';

  GlobalKey<SliverAnimatedListState>? listKey;

  bool get isUploading => _isUploading;

  double? get uploadProgress => _uploadProgress;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  List<Document> get currentDisplayItems => _currentDisplayItems;

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

  void listenToDocuments(String userId) {
    if (_isListening) return;
    _setLoading(true);
    _documentsSubscription?.cancel();
    _documentsSubscription =
        _repository.getDocumentsStream(userId).listen((newDocs) async {
      final processedNewDocs = await _processDocuments(newDocs, userId);
      _documents = processedNewDocs;
      _updateDisplayList();
      _setLoading(false);
    }, onError: (error) {
      _setErrorMessage('Erro ao carregar os documentos.');
      _setLoading(false);
    });
    _isListening = true;
  }

  void _updateDisplayList() {
    final oldList = List<Document>.from(_currentDisplayItems);
    final List<Document> newList = List.from(_documents);

    if (_searchQuery.isNotEmpty) {
      newList.retainWhere(
          (doc) => _sanitize(doc.documentName).contains(_searchQuery));
    }

    newList.sort((a, b) =>
        a.documentName.toLowerCase().compareTo(b.documentName.toLowerCase()));

    for (var i = oldList.length - 1; i >= 0; i--) {
      final oldItem = oldList[i];
      if (!newList.any((newItem) => newItem.id == oldItem.id)) {
        final indexToRemove =
            _currentDisplayItems.indexWhere((item) => item.id == oldItem.id);
        if (indexToRemove != -1) {
          _currentDisplayItems.removeAt(indexToRemove);
          listKey?.currentState?.removeItem(
            indexToRemove,
            (context, animation) => AnimatedListItem(
              animation: animation,
              child: DocumentListTile(key: ValueKey(oldItem.id), doc: oldItem),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }

    for (var i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      final oldIndex =
          _currentDisplayItems.indexWhere((item) => item.id == newItem.id);

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
    final docs = await _repository.getDocumentsForUser(userId);
    final processedDocs = await _processDocuments(docs, userId);
    _documents = processedDocs;
    _updateDisplayList();
    _setLoading(false);
  }

  Future<List<Document>> _processDocuments(
      List<Document> docs, String userId) async {
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

      final mainVersion = versions.firstWhere((v) => v.isPrincipal,
          orElse: () => versions.first);
      final otherVersions =
          versions.where((v) => v.id != mainVersion.id).toList();
      result.add(mainVersion.copyWith(versions: otherVersions));
    });

    result.sort((a, b) =>
        a.documentName.toLowerCase().compareTo(b.documentName.toLowerCase()));
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
      String userId, Document document, Document originalDocument) async {
    _setLoading(true);
    try {
      final originalAttachments = originalDocument.attachments;
      final currentAttachments = document.attachments;
      final attachmentsToDelete = originalAttachments
          .where((att) =>
              !currentAttachments.any((cAtt) => cAtt.driveId == att.driveId))
          .toList();

      for (final attachment in attachmentsToDelete) {
        await deleteAttachmentFile(attachment);
      }

      await _repository.updateDocument(userId, document);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível atualizar o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      for (final attachment in document.attachments) {
        await deleteAttachmentFile(attachment);
      }
      for (final version in document.versions) {
        for (final attachment in version.attachments) {
          await deleteAttachmentFile(attachment);
        }
      }

      await _repository.deleteDocument(userId, document.id!);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível excluir o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setAsPrincipal(
      String userId, Document newPrincipal, List<Document> allVersions) async {
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp', 'pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase() ?? '';

        final driveFile = await _driveService.uploadFile(file, (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        });

        if (driveFile == null || driveFile.id == null) {
          _setErrorMessage(
              'Falha ao fazer upload do arquivo para o Google Drive.');
          return null;
        }

        return Attachment(
          name: result.files.single.name,
          type: extension,
          driveId: driveFile.id!,
        );
      }
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
    final filePath =
        p.join(dir.path, '${attachment.driveId}-${attachment.name}');
    return File(filePath);
  }

  Future<File?> getAttachmentFile(Attachment attachment) async {
    try {
      final file = await _getLocalFile(attachment);

      if (await file.exists()) {
        return file;
      } else {
        final bytes = await _driveService.downloadFile(attachment.driveId);
        if (bytes == null) {
          _setErrorMessage('Não foi possível baixar o anexo do Google Drive.');
          return null;
        }
        await file.writeAsBytes(bytes);
        return file;
      }
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
