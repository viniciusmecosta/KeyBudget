import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DocumentViewModel extends ChangeNotifier {
  final DocumentRepository _repository = DocumentRepository();
  StreamSubscription? _documentsSubscription;
  bool _isListening = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Document> _documents = [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<Document> get documents => _documents;

  void listenToDocuments(String userId) {
    if (_isListening) return;
    _setLoading(true);
    _documentsSubscription?.cancel();
    _documentsSubscription =
        _repository.getDocumentsStream(userId).listen((docs) async {
      final processedDocs = await _processDocuments(docs, userId);
      _documents = processedDocs;
      _setLoading(false);
    }, onError: (error) {
      _setErrorMessage('Erro ao carregar os documentos.');
      _setLoading(false);
    });
    _isListening = true;
  }

  Future<void> forceRefresh(String userId) async {
    _setLoading(true);
    final docs = await _repository.getDocumentsForUser(userId);
    final processedDocs = await _processDocuments(docs, userId);
    _documents = processedDocs;
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
        if (a.dataExpedicao == null && b.dataExpedicao == null) return 0;
        if (a.dataExpedicao == null) return 1;
        if (b.dataExpedicao == null) return -1;
        return b.dataExpedicao!.compareTo(a.dataExpedicao!);
      });

      final mainVersion = versions.firstWhere((v) => v.isPrincipal,
          orElse: () => versions.first);
      final otherVersions =
          versions.where((v) => v.id != mainVersion.id).toList();
      result.add(mainVersion.copyWith(versoes: otherVersions));
    });

    result.sort((a, b) => a.nomeDocumento.compareTo(b.nomeDocumento));
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

  Future<bool> updateDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      await _repository.updateDocument(userId, document);
      await forceRefresh(userId);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível atualizar o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDocument(String userId, String documentId) async {
    _setLoading(true);
    try {
      await _repository.deleteDocument(userId, documentId);
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

  Future<Anexo?> pickAndConvertFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp', 'pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        return Anexo(
          nome: result.files.single.name,
          tipo: result.files.single.extension ?? '',
          base64: base64,
        );
      }
      return null;
    } catch (e) {
      _setErrorMessage('Erro ao selecionar o arquivo.');
      return null;
    }
  }

  Future<void> downloadAndOpenFile(Anexo anexo) async {
    try {
      final bytes = base64Decode(anexo.base64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${anexo.nome}');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      _setErrorMessage('Não foi possível abrir o anexo.');
    }
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
    _isListening = false;
    notifyListeners();
  }
}
