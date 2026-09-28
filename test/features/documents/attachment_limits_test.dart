import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

void main() {
  test('writes allowed download chunks to the final file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'keybudget-attachment',
    );
    addTearDown(() => directory.delete(recursive: true));
    final destination = File('${directory.path}/attachment.pdf');

    await DriveService.writeLimitedStreamToFile(
      Stream.fromIterable([
        [1, 2],
        [3, 4],
      ]),
      destination,
      maxBytes: 4,
    );

    expect(await destination.readAsBytes(), [1, 2, 3, 4]);
    expect(await File('${destination.path}.part').exists(), isFalse);
  });

  test('rejects oversized downloads and removes partial files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'keybudget-attachment',
    );
    addTearDown(() => directory.delete(recursive: true));
    final destination = File('${directory.path}/attachment.pdf');

    await expectLater(
      DriveService.writeLimitedStreamToFile(
        Stream.fromIterable([
          [1, 2],
          [3, 4, 5],
        ]),
        destination,
        maxBytes: 4,
      ),
      throwsA(isA<DriveFileTooLargeException>()),
    );

    expect(await destination.exists(), isFalse);
    expect(await File('${destination.path}.part').exists(), isFalse);
  });

  test('checks file signature as well as extension', () {
    expect(
      DocumentViewModel.matchesAttachmentFormat([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2d,
      ], 'pdf'),
      isTrue,
    );
    expect(
      DocumentViewModel.matchesAttachmentFormat([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2d,
      ], 'jpg'),
      isFalse,
    );
  });
}
