import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:key_budget/core/services/drive_connection_service.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/google_sign_in_session.dart';

class _User extends Fake implements firebase.User {
  _User(this.uid);

  @override
  final String uid;

  @override
  List<firebase.UserInfo> get providerData => [];
}

class _FirebaseAuth extends Fake implements firebase.FirebaseAuth {
  firebase.User? user = _User('firebase-user');

  @override
  firebase.User? get currentUser => user;
}

class _RecordingSession extends GoogleSignInSession {
  final interactionModes = <bool>[];
  GoogleSignInAccount? selectedAccount;
  void Function()? onAccount;
  int authorizationCount = 0;

  @override
  Future<GoogleSignInAccount?> account({
    required bool allowInteractive,
    bool refreshAuthentication = false,
    String? firebaseUserId,
    List<String> expectedGoogleAccountIds = const [],
    String? serverClientId,
  }) async {
    interactionModes.add(allowInteractive);
    onAccount?.call();
    return selectedAccount;
  }

  @override
  Future<GoogleSignInClientAuthorization?> authorizationFor(
    GoogleSignInAccount account,
    List<String> scopes, {
    required bool allowInteractive,
  }) async {
    authorizationCount++;
    return null;
  }
}

class _GoogleAccount extends Fake implements GoogleSignInAccount {}

class _Connections extends DriveConnectionService {
  DriveConnection? saved;
  GoogleSignInClientAuthorization? token;

  @override
  Future<DriveConnection?> readConnection(String userId) async => saved;

  @override
  Future<GoogleSignInClientAuthorization?> restoreAuthorization({
    required String userId,
    DriveConnection? fallback,
    List<String> expectedAccountIds = const [],
  }) async => token;
}

class _RecordingClient extends http.BaseClient {
  bool closed = false;
  String? authorization;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorization = request.headers['Authorization'];
    return http.StreamedResponse(Stream.value(<int>[]), 200);
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  for (final status in [200, 401, 503]) {
    test(
      'verification checks Drive API response $status without interactive login',
      () async {
        final google = _RecordingSession();
        final connections = _Connections()
          ..token = GoogleSignInClientAuthorization(accessToken: 'test-token');
        var requests = 0;
        final service = DriveService(
          firebaseAuth: _FirebaseAuth(),
          googleSession: google,
          connectionService: connections,
          httpClientFactory: () => MockClient((request) async {
            requests++;
            expect(request.url.path, '/drive/v3/files');
            expect(request.url.queryParameters['pageSize'], '1');
            expect(request.headers['Authorization'], 'Bearer test-token');
            return http.Response(
              status == 200
                  ? '{"files":[]}'
                  : '{"error":{"message":"unavailable","code":$status}}',
              status,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        if (status == 200) {
          expect(await service.verifyConnection(), isTrue);
        } else if (status == 401) {
          expect(await service.verifyConnection(), isFalse);
        } else {
          await expectLater(
            service.verifyConnection(),
            throwsA(isA<Exception>()),
          );
        }
        expect(requests, 1);
        expect(google.interactionModes, isEmpty);
      },
    );
  }

  test(
    'saved Drive access skips account selection after an app restart',
    () async {
      final session = _RecordingSession();
      final connections = _Connections()
        ..saved = const DriveConnection(
          accountId: 'google',
          email: 'drive@test.com',
        )
        ..token = const GoogleSignInClientAuthorization(
          accessToken: 'restored',
        );
      final drive = DriveService(
        googleSession: session,
        connectionService: connections,
        firebaseAuth: _FirebaseAuth(),
      );

      expect(await drive.ensureAuthorized(), isTrue);
      expect(session.interactionModes, isEmpty);
      expect(session.authorizationCount, 0);
    },
  );

  test(
    'disconnect prevents cached account use by documents and backups',
    () async {
      final session = _RecordingSession();
      final connections = _Connections()
        ..saved = const DriveConnection.disabled();
      final drive = DriveService(
        googleSession: session,
        connectionService: connections,
        firebaseAuth: _FirebaseAuth(),
      );

      expect(await drive.ensureAuthorized(), isFalse);
      expect(session.interactionModes, isEmpty);
    },
  );

  test(
    'Drive is silent by default even when a caller allows interaction',
    () async {
      final session = _RecordingSession();
      final drive = DriveService(
        googleSession: session,
        connectionService: _Connections(),
        firebaseAuth: _FirebaseAuth(),
      );

      expect(await drive.ensureAuthorized(), isFalse);
      expect(await drive.ensureAuthorized(allowInteractive: true), isFalse);
      expect(session.interactionModes, [false, false]);
    },
  );

  test(
    'explicit settings connection can authorize while background work stays silent',
    () async {
      final session = _RecordingSession();
      final drive = DriveService(
        googleSession: session,
        connectionService: _Connections(),
        firebaseAuth: _FirebaseAuth(),
        allowUserInteraction: true,
      );

      await drive.ensureAuthorized();
      await drive.ensureAuthorized(allowInteractive: false);

      expect(session.interactionModes, [true, false]);
    },
  );

  test(
    'Drive never requests a Google account without an app session',
    () async {
      final session = _RecordingSession();
      final auth = _FirebaseAuth()..user = null;
      final drive = DriveService(
        googleSession: session,
        connectionService: _Connections(),
        firebaseAuth: auth,
        allowUserInteraction: true,
      );

      expect(await drive.ensureAuthorized(), isFalse);
      expect(session.interactionModes, isEmpty);
    },
  );

  test('account switch stops Drive before requesting permission', () async {
    final auth = _FirebaseAuth();
    final session = _RecordingSession()
      ..selectedAccount = _GoogleAccount()
      ..onAccount = () => auth.user = _User('other-user');
    final drive = DriveService(
      googleSession: session,
      connectionService: _Connections(),
      firebaseAuth: auth,
      allowUserInteraction: true,
    );

    expect(await drive.ensureAuthorized(), isFalse);
    expect(session.authorizationCount, 0);
  });

  test(
    'GoogleAuthClient forwards authorization and closes its HTTP client',
    () async {
      final delegate = _RecordingClient();
      final client = GoogleAuthClient({
        'Authorization': 'Bearer token',
      }, client: delegate);

      await client.send(http.Request('GET', Uri.https('example.com', '/')));
      client.close();

      expect(delegate.authorization, 'Bearer token');
      expect(delegate.closed, isTrue);
    },
  );
}
