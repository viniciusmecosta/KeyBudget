import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:key_budget/core/services/google_sign_in_session.dart';

class _RecordingGoogleSignIn extends Fake implements GoogleSignIn {
  int initializationCount = 0;
  int restorationCount = 0;
  int interactiveCount = 0;
  bool cancelRestoration = false;
  bool failSignOut = false;
  GoogleSignInAccount? restoredAccount;
  Future<GoogleSignInAccount?>? restorationOperation;
  Future<GoogleSignInAccount>? interactiveOperation;
  final interactiveStarted = Completer<void>();
  final events = StreamController<GoogleSignInAuthenticationEvent>.broadcast();

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializationCount++;
  }

  @override
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      events.stream;

  @override
  Future<GoogleSignInAccount?>? attemptLightweightAuthentication({
    bool reportAllExceptions = false,
  }) {
    restorationCount++;
    if (cancelRestoration) {
      return Future.error(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
    }
    return restorationOperation ?? Future.value(restoredAccount);
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    interactiveCount++;
    if (!interactiveStarted.isCompleted) interactiveStarted.complete();
    return interactiveOperation ??
        Future.error(StateError('Autenticação interativa inesperada.'));
  }

  @override
  Future<void> signOut() async {
    if (failSignOut) throw StateError('sign-out failed');
  }
}

class _Account extends Fake implements GoogleSignInAccount {
  _Account(this.id, [this._authorizationClient]);

  @override
  final String id;

  final GoogleSignInAuthorizationClient? _authorizationClient;

  @override
  GoogleSignInAuthorizationClient get authorizationClient =>
      _authorizationClient!;
}

class _AuthorizationClient extends Fake
    implements GoogleSignInAuthorizationClient {
  int silentCount = 0;
  int consentCount = 0;
  GoogleSignInClientAuthorization? existing;
  Future<GoogleSignInClientAuthorization>? consentOperation;
  final consentStarted = Completer<void>();

  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
    List<String> scopes,
  ) async {
    silentCount++;
    return existing;
  }

  @override
  Future<GoogleSignInClientAuthorization> authorizeScopes(
    List<String> scopes,
  ) async {
    consentCount++;
    if (!consentStarted.isCompleted) consentStarted.complete();
    return consentOperation ??
        Future.error(StateError('Consentimento inesperado.'));
  }
}

void main() {
  GoogleSignInSession createSession(_RecordingGoogleSignIn googleSignIn) {
    final session = GoogleSignInSession(googleSignIn: googleSignIn);
    addTearDown(() async {
      await session.disposeForTesting();
      await googleSignIn.events.close();
    });
    return session;
  }

  test('background access never starts Google account selection', () async {
    final googleSignIn = _RecordingGoogleSignIn();
    final session = createSession(googleSignIn);

    expect(
      await session.account(allowInteractive: false, firebaseUserId: 'user'),
      isNull,
    );
    expect(
      await session.account(allowInteractive: false, firebaseUserId: 'user'),
      isNull,
    );
    expect(googleSignIn.initializationCount, 1);
    expect(googleSignIn.restorationCount, 0);
    expect(googleSignIn.interactiveCount, 0);
  });

  test('canceling account restoration never opens a second prompt', () async {
    final googleSignIn = _RecordingGoogleSignIn()..cancelRestoration = true;
    final session = createSession(googleSignIn);

    await expectLater(
      session.account(allowInteractive: true),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.code,
          'code',
          GoogleSignInExceptionCode.canceled,
        ),
      ),
    );
    expect(googleSignIn.restorationCount, 1);
    expect(googleSignIn.interactiveCount, 0);
  });

  test('later document and background access reuse the account', () async {
    final account = _Account('google-user');
    final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = account;
    final session = createSession(googleSignIn);

    for (final interactive in [true, true, false]) {
      expect(
        await session.account(
          allowInteractive: interactive,
          firebaseUserId: 'user',
        ),
        same(account),
      );
    }
    expect(googleSignIn.restorationCount, 1);
    expect(googleSignIn.interactiveCount, 0);
  });

  test(
    'explicit app login refreshes credentials while documents reuse them',
    () async {
      final first = _Account('google-user');
      final fresh = _Account('google-user');
      final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = first;
      final session = createSession(googleSignIn);
      expect(await session.account(allowInteractive: true), same(first));
      googleSignIn.restoredAccount = fresh;

      expect(
        await session.account(
          allowInteractive: true,
          refreshAuthentication: true,
        ),
        same(fresh),
      );
      expect(await session.account(allowInteractive: true), same(fresh));
      expect(googleSignIn.restorationCount, 2);
    },
  );

  test(
    'background work cannot reuse a different Firebase user account',
    () async {
      final googleSignIn = _RecordingGoogleSignIn()
        ..restoredAccount = _Account('google-user');
      final session = createSession(googleSignIn);
      await session.account(allowInteractive: true, firebaseUserId: 'first');

      expect(
        await session.account(
          allowInteractive: false,
          firebaseUserId: 'second',
        ),
        isNull,
      );
      expect(googleSignIn.restorationCount, 1);
      expect(googleSignIn.interactiveCount, 0);
    },
  );

  test('concurrent actions share the complete account selection', () async {
    final selected = Completer<GoogleSignInAccount>();
    final googleSignIn = _RecordingGoogleSignIn()
      ..interactiveOperation = selected.future;
    final session = createSession(googleSignIn);
    final first = session.account(allowInteractive: true);
    await googleSignIn.interactiveStarted.future;
    final second = session.account(allowInteractive: true);
    await Future<void>.delayed(Duration.zero);

    expect(googleSignIn.restorationCount, 1);
    expect(googleSignIn.interactiveCount, 1);
    final account = _Account('google-user');
    selected.complete(account);
    expect(await Future.wait([first, second]), everyElement(same(account)));
  });

  test('shared selection validates each caller account identity', () async {
    final restored = Completer<GoogleSignInAccount?>();
    final googleSignIn = _RecordingGoogleSignIn()
      ..restorationOperation = restored.future;
    final session = createSession(googleSignIn);
    final first = session.account(
      allowInteractive: true,
      expectedGoogleAccountIds: ['first'],
    );
    final second = session.account(
      allowInteractive: true,
      expectedGoogleAccountIds: ['second'],
    );
    restored.complete(_Account('first'));

    expect((await first)?.id, 'first');
    expect(await second, isNull);
    expect(googleSignIn.restorationCount, 1);
  });

  test('sign-out discards a late account selection and SDK event', () async {
    final selected = Completer<GoogleSignInAccount>();
    final googleSignIn = _RecordingGoogleSignIn()
      ..interactiveOperation = selected.future;
    final session = createSession(googleSignIn);
    final operation = session.account(allowInteractive: true);
    await googleSignIn.interactiveStarted.future;
    final cancelled = expectLater(
      operation,
      throwsA(isA<GoogleSignInException>()),
    );
    await session.signOut();
    final account = _Account('old-user');
    googleSignIn.events.add(
      GoogleSignInAuthenticationEventSignIn(user: account),
    );
    selected.complete(account);
    await cancelled;

    expect(session.currentAccount, isNull);
    expect(await session.account(allowInteractive: false), isNull);
  });

  test('failed SDK sign-out still clears the app account cache', () async {
    final googleSignIn = _RecordingGoogleSignIn()
      ..restoredAccount = _Account('google-user')
      ..failSignOut = true;
    final session = createSession(googleSignIn);
    await session.account(allowInteractive: true);

    await expectLater(session.signOut(), throwsStateError);

    expect(session.currentAccount, isNull);
    expect(await session.account(allowInteractive: false), isNull);
    expect(googleSignIn.restorationCount, 1);
  });

  test(
    'SDK cancellation stream errors are consumed without another login',
    () async {
      final googleSignIn = _RecordingGoogleSignIn();
      final session = createSession(googleSignIn);
      await session.account(allowInteractive: false);
      googleSignIn.events.addError(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
      await Future<void>.delayed(Duration.zero);

      expect(googleSignIn.restorationCount, 0);
      expect(googleSignIn.interactiveCount, 0);
    },
  );

  test('concurrent Drive operations share one permission prompt', () async {
    final consent = Completer<GoogleSignInClientAuthorization>();
    final client = _AuthorizationClient()..consentOperation = consent.future;
    final account = _Account('google-user', client);
    final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = account;
    final session = createSession(googleSignIn);
    await session.account(allowInteractive: true);
    final first = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: true);
    await client.consentStarted.future;
    final second = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: true);
    final background = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: false);
    final token = GoogleSignInClientAuthorization(accessToken: 'token');
    consent.complete(token);

    expect(
      await Future.wait([first, second, background]),
      everyElement(same(token)),
    );
    expect(client.silentCount, 1);
    expect(client.consentCount, 1);
  });

  test('background missing permissions never triggers consent', () async {
    final client = _AuthorizationClient();
    final account = _Account('google-user', client);
    final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = account;
    final session = createSession(googleSignIn);
    await session.account(allowInteractive: true);

    expect(
      await session.authorizationFor(account, [
        'drive',
      ], allowInteractive: false),
      isNull,
    );
    expect(client.silentCount, 1);
    expect(client.consentCount, 0);
  });

  test('canceling shared Drive consent does not open another prompt', () async {
    final consent = Completer<GoogleSignInClientAuthorization>();
    final client = _AuthorizationClient()..consentOperation = consent.future;
    final account = _Account('google-user', client);
    final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = account;
    final session = createSession(googleSignIn);
    await session.account(allowInteractive: true);
    final first = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: true);
    await client.consentStarted.future;
    final second = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: true);
    final firstCancelled = expectLater(
      first,
      throwsA(isA<GoogleSignInException>()),
    );
    final secondCancelled = expectLater(
      second,
      throwsA(isA<GoogleSignInException>()),
    );
    consent.completeError(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    await Future.wait([firstCancelled, secondCancelled]);

    expect(client.consentCount, 1);
  });

  test('Drive permission response after sign-out is ignored', () async {
    final consent = Completer<GoogleSignInClientAuthorization>();
    final client = _AuthorizationClient()..consentOperation = consent.future;
    final account = _Account('google-user', client);
    final googleSignIn = _RecordingGoogleSignIn()..restoredAccount = account;
    final session = createSession(googleSignIn);
    await session.account(allowInteractive: true);
    final operation = session.authorizationFor(account, [
      'drive',
    ], allowInteractive: true);
    await client.consentStarted.future;
    await session.signOut();
    consent.complete(GoogleSignInClientAuthorization(accessToken: 'stale'));

    expect(await operation, isNull);
  });
}
