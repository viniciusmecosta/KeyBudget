import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/drive_connection_service.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/user/view/drive_connection_screen.dart';

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
      expect(drive.silentCount, 2);

      await tester.tap(find.text('Desconectar Drive'));
      await tester.pumpAndSettle();
      expect(connections.connection?.enabled, isFalse);
      expect(find.text('Conectar Google Drive'), findsOneWidget);
      expect(drive.interactiveCount, 0);
    },
  );
}
