import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSession {
  GoogleSignInSession._();

  static final GoogleSignInSession instance = GoogleSignInSession._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  Future<GoogleSignInAccount?>? _restoration;
  Future<GoogleSignInAccount>? _interactiveSignIn;
  Future<GoogleSignInClientAuthorization?>? _authorization;
  String? _authorizationAccountId;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  GoogleSignInAccount? _account;
  String? _boundFirebaseUid;

  GoogleSignInAccount? get currentAccount => _account;

  Future<void> initialize({String? serverClientId}) async {
    final existing = _initialization;
    if (existing != null) return existing;
    final operation = _initialize(serverClientId);
    _initialization = operation;
    try {
      await operation;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize(String? serverClientId) async {
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _events = _googleSignIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn(:final user):
          if (_account?.id != user.id) {
            _authorization = null;
            _authorizationAccountId = null;
          }
          _account = user;
        case GoogleSignInAuthenticationEventSignOut():
          _account = null;
          _authorization = null;
          _authorizationAccountId = null;
      }
    });
  }

  Future<GoogleSignInAccount?> account({
    required bool allowInteractive,
    String? firebaseUserId,
    List<String> expectedGoogleAccountIds = const [],
    String? serverClientId,
  }) async {
    await initialize(serverClientId: serverClientId);
    if (firebaseUserId != null &&
        _boundFirebaseUid != null &&
        _boundFirebaseUid != firebaseUserId) {
      if (!allowInteractive) return null;
      await _googleSignIn.signOut();
      _account = null;
      _authorization = null;
      _authorizationAccountId = null;
      _boundFirebaseUid = null;
    }
    if (_account case final account?) {
      if (expectedGoogleAccountIds.isNotEmpty &&
          !expectedGoogleAccountIds.contains(account.id)) {
        if (!allowInteractive) return null;
        await _googleSignIn.signOut();
        _account = null;
        _authorization = null;
        _authorizationAccountId = null;
        _boundFirebaseUid = null;
      } else {
        if (firebaseUserId != null) _boundFirebaseUid = firebaseUserId;
        return account;
      }
    }

    final restoration = _restoration ??= _restoreAccount();
    GoogleSignInAccount? restored;
    try {
      restored = await restoration;
    } catch (_) {
      restored = null;
    } finally {
      if (identical(_restoration, restoration)) _restoration = null;
    }
    if (restored != null &&
        expectedGoogleAccountIds.isNotEmpty &&
        !expectedGoogleAccountIds.contains(restored.id)) {
      if (!allowInteractive) return null;
      await _googleSignIn.signOut();
      restored = null;
    }
    if (restored != null) {
      _account = restored;
      if (firebaseUserId != null) _boundFirebaseUid = firebaseUserId;
      return restored;
    }
    if (!allowInteractive) return null;

    final existing = _interactiveSignIn;
    if (existing != null) return existing;
    final operation = _googleSignIn.authenticate();
    _interactiveSignIn = operation;
    try {
      final signedIn = await operation;
      if (expectedGoogleAccountIds.isNotEmpty &&
          !expectedGoogleAccountIds.contains(signedIn.id)) {
        await _googleSignIn.signOut();
        _account = null;
        _boundFirebaseUid = null;
        throw StateError('A conta Google não corresponde à conta do app.');
      }
      _account = signedIn;
      if (firebaseUserId != null) _boundFirebaseUid = firebaseUserId;
      return signedIn;
    } finally {
      if (identical(_interactiveSignIn, operation)) {
        _interactiveSignIn = null;
      }
    }
  }

  Future<GoogleSignInAccount?> _restoreAccount() async {
    final attempt = _googleSignIn.attemptLightweightAuthentication();
    if (attempt == null) return _account;
    return attempt;
  }

  Future<GoogleSignInClientAuthorization?> authorizationFor(
    GoogleSignInAccount account,
    List<String> scopes, {
    required bool allowInteractive,
  }) async {
    final current = await account.authorizationClient.authorizationForScopes(
      scopes,
    );
    if (current != null || !allowInteractive) return current;

    final pending = _authorization;
    if (pending != null && _authorizationAccountId == account.id) {
      return pending;
    }
    final operation = _authorize(account, scopes);
    _authorization = operation;
    _authorizationAccountId = account.id;
    try {
      return await operation;
    } finally {
      if (identical(_authorization, operation)) {
        _authorization = null;
        _authorizationAccountId = null;
      }
    }
  }

  Future<GoogleSignInClientAuthorization> _authorize(
    GoogleSignInAccount account,
    List<String> scopes,
  ) async {
    await account.authorizationClient.authorizeScopes(scopes);
    final authorization = await account.authorizationClient
        .authorizationForScopes(scopes);
    if (authorization == null) {
      throw StateError('Google Drive authorization was not returned.');
    }
    return authorization;
  }

  Future<void> signOut() async {
    await initialize();
    await _googleSignIn.signOut();
    _account = null;
    _authorization = null;
    _authorizationAccountId = null;
    _boundFirebaseUid = null;
  }

  Future<void> disposeForTesting() async {
    await _events?.cancel();
    _events = null;
    _initialization = null;
    _restoration = null;
    _interactiveSignIn = null;
    _authorization = null;
    _authorizationAccountId = null;
    _boundFirebaseUid = null;
    _account = null;
  }
}
