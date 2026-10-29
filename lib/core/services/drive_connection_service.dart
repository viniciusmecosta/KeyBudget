import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as platform;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:passfin/core/services/google_sign_in_session.dart';

class DriveConnection {
  const DriveConnection({required this.accountId, required this.email})
    : enabled = true;

  const DriveConnection.disabled()
    : enabled = false,
      accountId = '',
      email = '';

  final bool enabled;
  final String accountId;
  final String email;
}

class DriveConnectionService {
  DriveConnectionService({
    FlutterSecureStorage? storage,
    GoogleSignInSession? googleSession,
    platform.GoogleSignInPlatform? googlePlatform,
    bool? restoreNativeAccount,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _googleSession = googleSession ?? GoogleSignInSession.instance,
       _customPlatform = googlePlatform,
       _restoreNativeAccount =
           restoreNativeAccount ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.iOS ||
                   defaultTargetPlatform == TargetPlatform.macOS));

  static final instance = DriveConnectionService();

  final FlutterSecureStorage _storage;
  final GoogleSignInSession _googleSession;
  final platform.GoogleSignInPlatform? _customPlatform;
  final bool _restoreNativeAccount;
  final _generations = <String, int>{};
  final _requests = <String, Future<GoogleSignInClientAuthorization?>>{};
  final _writes = <String, Future<void>>{};

  platform.GoogleSignInPlatform get _platform =>
      _customPlatform ?? platform.GoogleSignInPlatform.instance;

  String _key(String userId) => 'drive_connection.$userId';

  Future<DriveConnection?> readConnection(String userId) async {
    final pendingWrite = _writes[userId];
    if (pendingWrite != null) await pendingWrite;
    final encoded = await _storage.read(key: _key(userId));
    if (encoded == null) return null;
    try {
      final data = jsonDecode(encoded);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['enabled'] != true) {
        return const DriveConnection.disabled();
      }
      final id = data['accountId'];
      final email = data['email'];
      if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
        return const DriveConnection.disabled();
      }
      return DriveConnection(accountId: id, email: email);
    } catch (_) {
      return const DriveConnection.disabled();
    }
  }

  Future<void> saveConnection(String userId, DriveConnection connection) async {
    final generation = (_generations[userId] ?? 0) + 1;
    _generations[userId] = generation;
    final value = jsonEncode({
      'version': 1,
      'enabled': connection.enabled,
      if (connection.enabled) ...{
        'accountId': connection.accountId,
        'email': connection.email,
      },
    });
    final operation = _writeConnection(
      userId,
      value,
      generation,
      _writes[userId],
    );
    _writes[userId] = operation;
    try {
      await operation;
    } finally {
      if (identical(_writes[userId], operation)) _writes.remove(userId);
    }
  }

  Future<void> _writeConnection(
    String userId,
    String value,
    int generation,
    Future<void>? previous,
  ) async {
    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }
    if (_generations[userId] != generation) return;
    await _storage.write(key: _key(userId), value: value);
  }

  Future<void> disconnect(String userId) =>
      saveConnection(userId, const DriveConnection.disabled());

  Future<GoogleSignInClientAuthorization?> restoreAuthorization({
    required String userId,
    DriveConnection? fallback,
    List<String> expectedAccountIds = const [],
  }) async {
    final generation = _generations[userId] ?? 0;
    final expectedIds = expectedAccountIds.toList()..sort();
    final key =
        '$userId:$generation:${fallback?.accountId}:${expectedIds.join(' ')}';
    final existing = _requests[key];
    if (existing != null) return existing;
    final operation = _restoreAuthorization(
      userId,
      fallback,
      expectedAccountIds,
      generation,
    );
    _requests[key] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_requests[key], operation)) _requests.remove(key);
    }
  }

  Future<GoogleSignInClientAuthorization?> _restoreAuthorization(
    String userId,
    DriveConnection? fallback,
    List<String> expectedAccountIds,
    int generation,
  ) async {
    final saved = await readConnection(userId);
    final connection = saved ?? fallback;
    if (connection == null || !connection.enabled) return null;
    if (connection.accountId.isEmpty || connection.email.isEmpty) return null;
    if (expectedAccountIds.isNotEmpty &&
        !expectedAccountIds.contains(connection.accountId)) {
      return null;
    }
    await _googleSession.initialize();
    if (_restoreNativeAccount) {
      final attempt = _platform.attemptLightweightAuthentication(
        const platform.AttemptLightweightAuthenticationParameters(),
      );
      final restored = attempt == null ? null : await attempt;
      if (restored?.user.id != connection.accountId) return null;
    }
    if ((_generations[userId] ?? 0) != generation) return null;
    final token = await _platform.clientAuthorizationTokensForScopes(
      platform.ClientAuthorizationTokensForScopesParameters(
        request: platform.AuthorizationRequestDetails(
          scopes: const [drive.DriveApi.driveFileScope],
          userId: connection.accountId,
          email: connection.email,
          promptIfUnauthorized: false,
        ),
      ),
    );
    if (token == null || (_generations[userId] ?? 0) != generation) return null;
    if (saved == null) {
      await saveConnection(userId, connection);
      if (_generations[userId] != generation + 1) return null;
    }
    return GoogleSignInClientAuthorization(accessToken: token.accessToken);
  }
}

final driveConnectionServiceProvider = Provider<DriveConnectionService>(
  (ref) => DriveConnectionService.instance,
);
