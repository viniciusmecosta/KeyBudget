import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
          if (kDebugMode) {
            print('Erro ao carregar documentos: $error');
          }
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
        if (a.issueDate == null && b.issueDate == null) return 0;
        if (a.issueDate == null) return 1;
        if (b.issueDate == null) return -1;
        return b.issueDate!.compareTo(a.issueDate!);
      });

      final mainVersion =
      versions.firstWhere((v) => v.isPrincipal, orElse: () => versions.first);
      final otherVersions =
      versions.where((v) => v.id != mainVersion.id).toList();
      result.add(mainVersion.copyWith(versions: otherVersions));
    });

    result.sort((a, b) => a.documentName.compareTo(b.documentName));
    return result;
  }

  Future<String?> addDocument(String userId, Document document) async {
    _setLoading(true);
    try {
      final newId = await _repository.addDocument(userId, document);
      return newId;
    } catch (e) {
      _setErrorMessage('Não foi possível adicionar o documento.');
      if (kDebugMode) {
        print('Erro ao adicionar documento: $e');
      }
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
      if (kDebugMode) {
        print('Erro ao atualizar documento: $e');
      }
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
      if (kDebugMode) {
        print('Erro ao excluir documento: $e');
      }
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
      if (kDebugMode) {
        print('Erro ao definir como principal: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Attachment?> pickAndConvertFile() async {
    const firestoreSizeLimit = 1048576;
    const maxFileSize = 5 * 1048576;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp', 'pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        List<int> bytes = await file.readAsBytes();

        if (bytes.length > firestoreSizeLimit) {
          if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
            int quality = 85;
            while (bytes.length > firestoreSizeLimit && quality > 10) {
              final compressedBytes =
              await FlutterImageCompress.compressWithList(
                Uint8List.fromList(bytes),
                quality: quality,
              );
              bytes = compressedBytes;
              quality -= 5;
            }
          } else if (extension == 'pdf') {
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            document.compressionLevel = PdfCompressionLevel.best;
            final compressedBytes = await document.save();
            document.dispose();
            bytes = compressedBytes.toList();
          }
        }

        if (bytes.length > maxFileSize) {
          _setErrorMessage(
              'O arquivo é muito grande (${(bytes.length / 1048576).toStringAsFixed(2)}MB). O tamanho máximo permitido, mesmo após a compressão, é de 5MB.');
          return null;
        }

        final base64 = base64Encode(bytes);

        return Attachment(
          name: result.files.single.name,
          type: extension,
          base64: base64,
        );
      }
      return null;
    } catch (e) {
      _setErrorMessage('Erro ao selecionar ou processar o arquivo.');
      return null;
    }
  }

  Future<void> openFile(Attachment attachment) async {
    try {
      final bytes = base64Decode(attachment.base64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${attachment.name}');
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