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

  Future<List<Document>> _processDocuments(
      List<Document> docs, String userId) async {
    final docMap = {for (var doc in docs) doc.id: doc};
    final parentDocs = <String?, List<Document>>{};

    for (var doc in docs) {
      if (doc.documentoPaiId != null) {
        parentDocs.putIfAbsent(doc.documentoPaiId, () => []).add(doc);
      }
    }

    final result =
    docs.where((doc) => doc.documentoPaiId == null).map<Document>((doc) {
      final allVersions = <Document>[doc, ...(parentDocs[doc.id] ?? [])];
      allVersions.sort((a, b) => b.dataExpedicao.compareTo(a.dataExpedicao));
      final mainVersion =
      allVersions.firstWhere((v) => v.isPrincipal, orElse: () => doc);
      final otherVersions =
      allVersions.where((v) => v.id != mainVersion.id).toList();

      return mainVersion.copyWith(
          versoes: otherVersions,
          documentoPai:
          doc.documentoPaiId != null ? docMap[doc.documentoPaiId] : null);
    }).toList();

    result.sort((a, b) => b.nomeDocumento.compareTo(a.nomeDocumento));
    return result;
  }

  Future<bool> addDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      await _repository.addDocument(userId, document);
      return true;
    } catch (e) {
      _setErrorMessage('Não foi possível adicionar o documento.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      await _repository.updateDocument(userId, document);
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