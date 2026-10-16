import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as platform;
import 'package:key_budget/core/services/drive_connection_service.dart';
import 'package:key_budget/core/services/google_sign_in_session.dart';

class _Storage extends Fake implements FlutterSecureStorage {
  final values = <String, String>{};
  Future<void>? writeGate;
  Completer<void>? writeStarted;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final started = writeStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = writeGate;
    if (gate != null) await gate;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

class _Session extends GoogleSignInSession {
  @override
  Future<void> initialize({String? serverClientId}) async {}
}

class _Platform extends Fake implements platform.GoogleSignInPlatform {
  final requests = <platform.AuthorizationRequestDetails>[];
  int restorationCount = 0;
  platform.ClientAuthorizationTokenData? token =
      const platform.ClientAuthorizationTokenData(accessToken: 'fresh-token');
  Future<platform.ClientAuthorizationTokenData?>? pending;
  platform.AuthenticationResults? restored;
  final requestStarted = Completer<void>();

  @override
  Future<platform.ClientAuthorizationTokenData?>
  clientAuthorizationTokensForScopes(
    platform.ClientAuthorizationTokensForScopesParameters params,
  ) async {
    requests.add(params.request);
    if (!requestStarted.isCompleted) requestStarted.complete();
    return pending ?? token;
  }

  @override
  Future<platform.AuthenticationResults?>? attemptLightweightAuthentication(
    platform.AttemptLightweightAuthenticationParameters params,
  ) {
    restorationCount++;
    return Future.value(restored);
  }
}

void main() {
  const account = DriveConnection(
    accountId: 'google-user',
    email: 'drive@test.com',
  );

  DriveConnectionService service(
    _Storage storage,
    _Platform sdk, {
    bool restoreNativeAccount = false,
  }) => DriveConnectionService(
    storage: storage,
    googleSession: _Session(),
    googlePlatform: sdk,
    restoreNativeAccount: restoreNativeAccount,
  );

  test(
    'saved Drive connection restores after process restart without login UI',
    () async {
      final storage = _Storage();
      await service(storage, _Platform()).saveConnection('user', account);
      final sdk = _Platform();
      final restarted = service(storage, sdk);

      final token = await restarted.restoreAuthorization(userId: 'user');

      expect(token?.accessToken, 'fresh-token');
      expect(sdk.restorationCount, 0);
      expect(sdk.requests.single.userId, account.accountId);
      expect(sdk.requests.single.email, account.email);
      expect(sdk.requests.single.promptIfUnauthorized, isFalse);
      expect(storage.values.values.single, isNot(contains('fresh-token')));
    },
  );

  test('Drive connection is isolated by Firebase user', () async {
    final storage = _Storage();
    final sdk = _Platform();
    final connection = service(storage, sdk);
    await connection.saveConnection('first', account);

    expect(await connection.restoreAuthorization(userId: 'second'), isNull);
    expect(sdk.requests, isEmpty);
  });

  test('a disconnect finishes after an older connection write', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    final storage = _Storage()
      ..writeGate = gate.future
      ..writeStarted = started;
    final connection = service(storage, _Platform());
    final saving = connection.saveConnection('user', account);
    await started.future;
    final disconnecting = connection.disconnect('user');
    gate.complete();
    await Future.wait([saving, disconnecting]);

    expect((await connection.readConnection('user'))?.enabled, isFalse);
  });

  test(
    'disconnect persists and blocks automatic legacy reconnection',
    () async {
      final storage = _Storage();
      final sdk = _Platform();
      final connection = service(storage, sdk);
      await connection.saveConnection('user', account);
      await connection.disconnect('user');
      final restarted = service(storage, sdk);

      expect(
        await restarted.restoreAuthorization(userId: 'user', fallback: account),
        isNull,
      );
      expect((await restarted.readConnection('user'))?.enabled, isFalse);
      expect(sdk.requests, isEmpty);
    },
  );

  test('existing Google consent migrates silently for legacy users', () async {
    final storage = _Storage();
    final sdk = _Platform();
    final connection = service(storage, sdk);

    expect(
      (await connection.restoreAuthorization(
        userId: 'user',
        fallback: account,
        expectedAccountIds: [account.accountId],
      ))?.accessToken,
      'fresh-token',
    );
    expect(
      (await connection.readConnection('user'))?.accountId,
      account.accountId,
    );
    expect(sdk.restorationCount, 0);
    expect(sdk.requests.single.promptIfUnauthorized, isFalse);
  });

  test('wrong Google identity is rejected before requesting tokens', () async {
    final storage = _Storage();
    final sdk = _Platform();
    final connection = service(storage, sdk);
    await connection.saveConnection('user', account);

    expect(
      await connection.restoreAuthorization(
        userId: 'user',
        expectedAccountIds: ['other-google-user'],
      ),
      isNull,
    );
    expect(sdk.requests, isEmpty);
  });

  test('revoked consent stays pending without showing a picker', () async {
    final storage = _Storage();
    final sdk = _Platform()..token = null;
    final connection = service(storage, sdk);
    await connection.saveConnection('user', account);

    expect(await connection.restoreAuthorization(userId: 'user'), isNull);
    expect(sdk.requests.single.promptIfUnauthorized, isFalse);
    expect(sdk.restorationCount, 0);
    expect((await connection.readConnection('user'))?.enabled, isTrue);
  });

  test('concurrent restores share a single silent token request', () async {
    final storage = _Storage();
    final token = Completer<platform.ClientAuthorizationTokenData?>();
    final sdk = _Platform()..pending = token.future;
    final connection = service(storage, sdk);
    await connection.saveConnection('user', account);
    final first = connection.restoreAuthorization(userId: 'user');
    await sdk.requestStarted.future;
    final second = connection.restoreAuthorization(userId: 'user');
    token.complete(
      const platform.ClientAuthorizationTokenData(accessToken: 'token'),
    );

    final results = await Future.wait([first, second]);
    expect(results.map((result) => result?.accessToken), ['token', 'token']);
    expect(sdk.requests, hasLength(1));
  });

  test('disconnect ignores an authorization that completes later', () async {
    final storage = _Storage();
    final token = Completer<platform.ClientAuthorizationTokenData?>();
    final sdk = _Platform()..pending = token.future;
    final connection = service(storage, sdk);
    await connection.saveConnection('user', account);
    final operation = connection.restoreAuthorization(userId: 'user');
    await sdk.requestStarted.future;
    await connection.disconnect('user');
    token.complete(
      const platform.ClientAuthorizationTokenData(accessToken: 'old'),
    );

    expect(await operation, isNull);
    expect((await connection.readConnection('user'))?.enabled, isFalse);
  });

  test(
    'Apple silent restore validates the selected account identity',
    () async {
      final storage = _Storage();
      final sdk = _Platform()
        ..restored = const platform.AuthenticationResults(
          user: platform.GoogleSignInUserData(
            email: 'other@test.com',
            id: 'other',
          ),
          authenticationTokens: platform.AuthenticationTokenData(idToken: null),
        );
      final connection = service(storage, sdk, restoreNativeAccount: true);
      await connection.saveConnection('user', account);

      expect(await connection.restoreAuthorization(userId: 'user'), isNull);
      expect(sdk.restorationCount, 1);
      expect(sdk.requests, isEmpty);
    },
  );
}
