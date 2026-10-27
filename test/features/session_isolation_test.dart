import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/document_model.dart';
import 'package:passfin/core/models/supplier_model.dart';
import 'package:passfin/features/documents/repository/document_repository.dart';
import 'package:passfin/features/documents/viewmodel/document_viewmodel.dart';
import 'package:passfin/features/suppliers/repository/supplier_repository.dart';
import 'package:passfin/features/suppliers/viewmodel/supplier_viewmodel.dart';

class _DocumentRepository extends DocumentRepository {
  final streams = <String, StreamController<List<Document>>>{};

  @override
  Stream<List<Document>> getDocumentsStream(String userId) => streams
      .putIfAbsent(userId, () => StreamController<List<Document>>.broadcast())
      .stream;

  @override
  Future<List<String>> getPendingAttachmentCleanup(String userId) async => [];
}

class _SupplierRepository extends SupplierRepository {
  final streams = <String, StreamController<List<Supplier>>>{};

  @override
  Stream<List<Supplier>> getSuppliersStreamForUser(String userId) => streams
      .putIfAbsent(userId, () => StreamController<List<Supplier>>.broadcast())
      .stream;
}

void main() {
  test(
    'documents from the previous account disappear before the next load',
    () async {
      final repository = _DocumentRepository();
      final viewModel = DocumentViewModel(repository: repository);

      viewModel.listenToDocuments('first');
      repository.streams['first']!.add([
        Document(id: 'private', documentName: 'Documento privado'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.currentDisplayItems.single.id, 'private');

      viewModel.listenToDocuments('second');
      expect(viewModel.currentDisplayItems, isEmpty);
      repository.streams['first']!.add([
        Document(id: 'stale', documentName: 'Documento antigo'),
      ]);
      repository.streams['second']!.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.currentDisplayItems, isEmpty);

      viewModel.dispose();
      for (final stream in repository.streams.values) {
        await stream.close();
      }
    },
  );

  test(
    'suppliers from the previous account disappear before the next load',
    () async {
      final repository = _SupplierRepository();
      final viewModel = SupplierViewModel(repository: repository);

      viewModel.listenToSuppliers('first');
      repository.streams['first']!.add([
        Supplier(id: 'private', name: 'Fornecedor privado'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.allSuppliers.single.id, 'private');

      viewModel.listenToSuppliers('second');
      expect(viewModel.allSuppliers, isEmpty);
      repository.streams['first']!.add([Supplier(id: 'stale', name: 'Antigo')]);
      repository.streams['second']!.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.allSuppliers, isEmpty);

      viewModel.dispose();
      for (final stream in repository.streams.values) {
        await stream.close();
      }
    },
  );
}
