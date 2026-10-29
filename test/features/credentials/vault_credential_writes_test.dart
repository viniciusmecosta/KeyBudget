import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/credential_model.dart';
import 'package:passfin/core/security/vault_crypto.dart';
import 'package:passfin/core/services/encryption_service.dart';
import 'package:passfin/features/credentials/repository/credential_repository.dart';
import 'package:passfin/features/credentials/viewmodel/credential_viewmodel.dart';

class _RecordingRepository extends CredentialRepository {
  final updates = <Credential>[];

  @override
  Future<void> updateCredential(String userId, Credential credential) async {
    updates.add(credential);
  }
}

void main() {
  test('credentials without a reserved ID cannot reach Firestore', () async {
    final repository = CredentialRepository();
    for (final id in [null, '']) {
      final credential = Credential(
        id: id,
        location: 'Portal',
        login: 'owner',
        encryptedPassword: 'value',
      );
      await expectLater(
        repository.addCredential('owner', credential),
        throwsArgumentError,
      );
      await expectLater(
        repository.restoreCredential('owner', credential),
        throwsArgumentError,
      );
      await expectLater(
        repository.updateCredential('owner', credential),
        throwsArgumentError,
      );
    }
  });

  test(
    'metadata edits authenticate the original password before writing',
    () async {
      final cipher = VaultCipher(keyId: 'key', key: List.filled(32, 7));
      final encryption = EncryptionService(cipher: cipher, userId: 'owner');
      final repository = _RecordingRepository();
      final viewModel = CredentialViewModel(
        repository: repository,
        encryptionService: encryption,
      );
      final credential = Credential(
        id: 'one',
        location: 'Portal',
        login: 'owner',
        encryptedPassword: encryption.encryptData('password', recordId: 'one'),
      );
      await viewModel.updateCredential(
        userId: 'owner',
        originalCredential: credential,
        location: 'Updated',
        login: 'owner',
      );
      expect(
        repository.updates.single.encryptedPassword,
        credential.encryptedPassword,
      );
      expect(repository.updates.single.location, 'Updated');
      for (final invalid in [
        credential.copyWith(encryptedPassword: 'iv:legacy'),
        credential.copyWith(id: 'another-id'),
        credential.copyWith(
          encryptedPassword: '${credential.encryptedPassword}bad',
        ),
      ]) {
        await expectLater(
          viewModel.updateCredential(
            userId: 'owner',
            originalCredential: invalid,
            location: 'Invalid',
            login: 'owner',
          ),
          throwsA(isA<VaultException>()),
        );
      }
      expect(repository.updates, hasLength(1));
      viewModel.dispose();
      cipher.dispose();
    },
  );

  test('an encryption service cannot write with a disposed session key', () {
    final cipher = VaultCipher(keyId: 'key', key: List.filled(32, 7));
    final encryption = EncryptionService(cipher: cipher, userId: 'owner');
    final encrypted = encryption.encryptData('password', recordId: 'one');
    cipher.dispose();
    expect(
      () => encryption.encryptData('new-password', recordId: 'one'),
      throwsA(
        isA<VaultException>().having(
          (e) => e.code,
          'code',
          VaultErrorCode.unavailable,
        ),
      ),
    );
    expect(
      () => encryption.decryptData(encrypted, recordId: 'one'),
      throwsA(
        isA<VaultException>().having(
          (e) => e.code,
          'code',
          VaultErrorCode.unavailable,
        ),
      ),
    );
  });
}
