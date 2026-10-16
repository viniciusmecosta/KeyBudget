import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSession {
  GoogleSignInSession({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static final GoogleSignInSession instance = GoogleSignInSession();

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;
  Future<void>? _signOutRequest;
  Future<GoogleSignInAccount>? _accountRequest;
  final _authorizations =
      <
        String,
        ({
          bool allowInteractive,
          Future<GoogleSignInClientAuthorization?> operation,
        })
      >{};
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  GoogleSignInAccount? _account;
  String? _boundFirebaseUid;
  int _sessionGeneration = 0;

  GoogleSignInAccount? get currentAccount => _account;

  Future<void> initialize({String? serverClientId}) async {
    final existing = _initialization;
    if (existing != null) return existing;
    final operation = _initialize(serverClientId);
    _initialization = operation;
    try {
      await operation;
    } catch (_) {
      if (identical(_initialization, operation)) _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize(String? serverClientId) async {
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _events = _googleSignIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn(:final user):
          if (_account?.id == user.id) _account = user;
        case GoogleSignInAuthenticationEventSignOut():
          _invalidateSession();
      }
    }, onError: (Object error, StackTrace stackTrace) {});
  }

  Future<GoogleSignInAccount?> account({
    required bool allowInteractive,
    bool refreshAuthentication = false,
    String? firebaseUserId,
    List<String> expectedGoogleAccountIds = const [],
    String? serverClientId,
  }) async {
    await initialize(serverClientId: serverClientId);
    final signingOut = _signOutRequest;
    if (signingOut != null) await signingOut;

    final cached = _account;
    final wrongUser =
        firebaseUserId != null &&
        _boundFirebaseUid != null &&
        _boundFirebaseUid != firebaseUserId;
    final wrongGoogleAccount =
        cached != null &&
        expectedGoogleAccountIds.isNotEmpty &&
        !expectedGoogleAccountIds.contains(cached.id);
    if (wrongUser || wrongGoogleAccount) {
      if (!allowInteractive) return null;
      await signOut();
    } else if (cached != null && !refreshAuthentication) {
      if (firebaseUserId != null) _boundFirebaseUid = firebaseUserId;
      return cached;
    }

    if (!allowInteractive) return null;

    final generation = _sessionGeneration;
    final operation = _accountRequest ??= _acquireAccount();
    final GoogleSignInAccount signedIn;
    try {
      signedIn = await operation;
    } finally {
      if (identical(_accountRequest, operation)) _accountRequest = null;
    }
    _ensureGeneration(generation);
    if (expectedGoogleAccountIds.isNotEmpty &&
        !expectedGoogleAccountIds.contains(signedIn.id)) {
      return null;
    }
    if (firebaseUserId != null &&
        _boundFirebaseUid != null &&
        _boundFirebaseUid != firebaseUserId) {
      return null;
    }
    if (firebaseUserId != null) _boundFirebaseUid = firebaseUserId;
    return signedIn;
  }

  Future<GoogleSignInAccount> _acquireAccount() async {
    final generation = _sessionGeneration;
    final restoration = _googleSignIn.attemptLightweightAuthentication(
      reportAllExceptions: true,
    );
    final restored = restoration == null ? null : await restoration;
    _ensureGeneration(generation);
    final signedIn = restored ?? await _googleSignIn.authenticate();
    _ensureGeneration(generation);
    if (_account?.id != signedIn.id) _boundFirebaseUid = null;
    _account = signedIn;
    return signedIn;
  }

  Future<GoogleSignInClientAuthorization?> authorizationFor(
    GoogleSignInAccount account,
    List<String> scopes, {
    required bool allowInteractive,
  }) async {
    if (_account?.id != account.id) return null;
    final generation = _sessionGeneration;
    final sortedScopes = scopes.toSet().toList()..sort();
    final key = '$generation:${account.id}:${sortedScopes.join(' ')}';
    final pending = _authorizations[key];
    if (pending != null) {
      final result = await pending.operation;
      if (_sessionGeneration != generation) return null;
      if (result != null || !allowInteractive || pending.allowInteractive) {
        return result;
      }
      if (identical(_authorizations[key]?.operation, pending.operation)) {
        _authorizations.remove(key);
      }
      return authorizationFor(account, scopes, allowInteractive: true);
    }

    final operation = _loadAuthorization(
      account,
      sortedScopes,
      allowInteractive: allowInteractive,
      generation: generation,
    );
    _authorizations[key] = (
      allowInteractive: allowInteractive,
      operation: operation,
    );
    try {
      final result = await operation;
      return _sessionGeneration == generation ? result : null;
    } finally {
      if (identical(_authorizations[key]?.operation, operation)) {
        _authorizations.remove(key);
      }
    }
  }

  Future<GoogleSignInClientAuthorization?> _loadAuthorization(
    GoogleSignInAccount account,
    List<String> scopes, {
    required bool allowInteractive,
    required int generation,
  }) async {
    final client = account.authorizationClient;
    final existing = await client.authorizationForScopes(scopes);
    if (_sessionGeneration != generation) return null;
    if (existing != null || !allowInteractive) return existing;
    final authorization = await client.authorizeScopes(scopes);
    if (_sessionGeneration != generation) return null;
    return authorization;
  }

  void _ensureGeneration(int generation) {
    if (_sessionGeneration != generation) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    }
  }

  void _invalidateSession() {
    _sessionGeneration++;
    _account = null;
    _boundFirebaseUid = null;
    _authorizations.clear();
  }

  Future<void> signOut() async {
    final existing = _signOutRequest;
    if (existing != null) return existing;
    _invalidateSession();
    final operation = _performSignOut();
    _signOutRequest = operation;
    try {
      await operation;
    } finally {
      if (identical(_signOutRequest, operation)) _signOutRequest = null;
    }
  }

  Future<void> _performSignOut() async {
    await initialize();
    await _googleSignIn.signOut();
  }

  Future<void> disposeForTesting() async {
    await _events?.cancel();
    _events = null;
    _initialization = null;
    _signOutRequest = null;
    _accountRequest = null;
    _invalidateSession();
  }
}
