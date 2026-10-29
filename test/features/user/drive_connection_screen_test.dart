import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/user_model.dart';
import 'package:passfin/core/services/drive_connection_service.dart';
import 'package:passfin/core/services/drive_service.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/user/view/drive_connection_screen.dart';

class _Connections extends DriveConnectionService {
  DriveConnection? connection;

  @override
  Future<DriveConnection?> readConnection(String userId) async => connection;

  @override
  Future<void> disconnect(String userId) async {
    connection = const DriveConnection.disabled();
  }
}

class _Drive extends DriveService {
  int interactiveCount = 0;
  int silentCount = 0;
  bool authorized = false;
  int verificationCount = 0;
  Completer<bool>? verification;

  @override
  Future<bool> verifyConnection() {
    verificationCount++;
    return verification?.future ?? Future.value(authorized);
  }

  final connection = Completer<bool>();

  @override
  Future<bool> ensureAuthorized({bool allowInteractive = true}) async {
    if (!allowInteractive) {
      silentCount++;
      return authorized;
    }
    interactiveCount++;
    return connection.future;
  }
}

Widget _app(_Connections connections, _Drive drive) {
  final auth = AuthViewModel(listenToAuthChanges: false)
    ..currentUser = User(id: 'user', name: 'Usuário', email: 'user@test.com');
  return ProviderScope(
    overrides: [
      authViewModelProvider.overrideWith((ref) => auth),
      driveConnectionServiceProvider.overrideWithValue(connections),
    ],
    child: MaterialApp(home: DriveConnectionScreen(driveService: drive)),
  );
}

void main() {
  testWidgets('settings opens silently and canceling never repeats the login', (
    tester,
  ) async {
    final connections = _Connections();
    final drive = _Drive();
    await tester.pumpWidget(_app(connections, drive));
    await tester.pumpAndSettle();
    expect(drive.interactiveCount, 0);
    expect(drive.silentCount, 1);

    await tester.tap(find.text('Conectar Google Drive'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    expect(drive.interactiveCount, 1);
    drive.connection.completeError(const DriveAuthorizationCancelled());
    await tester.pumpAndSettle();

    expect(find.text('Conectar Google Drive'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Não foi possível'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved connection shows its account and verification stays silent',
    (tester) async {
      final connections = _Connections()
        ..connection = const DriveConnection(
          accountId: 'google',
          email: 'drive@test.com',
        );
      final drive = _Drive()..authorized = true;
      await tester.pumpWidget(_app(connections, drive));
      await tester.pumpAndSettle();

      expect(find.text('Drive conectado'), findsOneWidget);
      expect(find.text('drive@test.com'), findsOneWidget);
      expect(drive.interactiveCount, 0);
      await tester.tap(find.text('Verificar conexão'));
      await tester.pumpAndSettle();
      expect(drive.interactiveCount, 0);
      expect(drive.silentCount, 1);
      expect(drive.verificationCount, 1);
      expect(find.textContaining('Conexão verificada.'), findsOneWidget);

      await tester.tap(find.text('Desconectar Drive'));
      await tester.pumpAndSettle();
      expect(connections.connection?.enabled, isFalse);
      expect(find.text('Conectar Google Drive'), findsOneWidget);
      expect(drive.interactiveCount, 0);
    },
  );
  testWidgets('verification times out and lets the user retry', (tester) async {
    final connections = _Connections()
      ..connection = const DriveConnection(
        accountId: 'google',
        email: 'drive@test.com',
      );
    final drive = _Drive()
      ..authorized = true
      ..verification = Completer<bool>();
    await tester.pumpWidget(_app(connections, drive));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verificar conexão'));
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(find.textContaining('O Drive não respondeu.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Reconectar Google Drive'), findsOneWidget);
    drive.verification!.complete(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Conexão verificada.'), findsNothing);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'verification reports ${fail ? "network failure" : "expired access"} and prevents duplicate requests',
      (tester) async {
        final connections = _Connections()
          ..connection = const DriveConnection(
            accountId: 'google',
            email: 'drive@test.com',
          );
        final drive = _Drive()
          ..authorized = true
          ..verification = Completer<bool>();
        await tester.pumpWidget(_app(connections, drive));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verificar conexão'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(drive.verificationCount, 1);
        if (fail) {
          drive.verification!.completeError(Exception('offline'));
        } else {
          drive.verification!.complete(false);
        }
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            fail ? 'O Drive não respondeu.' : 'O acesso expirou.',
          ),
          findsOneWidget,
        );
        expect(find.text('Reconectar Google Drive'), findsOneWidget);
        expect(drive.interactiveCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
