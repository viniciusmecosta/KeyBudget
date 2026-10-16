import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:key_budget/core/services/google_sign_in_session.dart';

class _RecordingGoogleSignIn extends Fake implements GoogleSignIn {
  int initializationCount = 0;
  int restorationCount = 0;
  int interactiveCount = 0;
  bool cancelRestoration = false;

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
      const Stream.empty();

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
    return Future.value(null);
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    interactiveCount++;
    throw StateError('A autenticação interativa não deveria ser chamada.');
  }
}

void main() {
  test('background access never starts Google account selection', () async {
    final googleSignIn = _RecordingGoogleSignIn();
    final session = GoogleSignInSession(googleSignIn: googleSignIn);

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
    final session = GoogleSignInSession(googleSignIn: googleSignIn);

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
}
