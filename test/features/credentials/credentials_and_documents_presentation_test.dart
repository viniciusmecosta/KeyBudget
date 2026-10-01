import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:key_budget/core/design_system/widgets/app_status_badge.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';
import 'package:key_budget/features/credentials/widgets/credential_list_tile.dart';
import 'package:key_budget/features/documents/utils/document_expiry_helper.dart';
import 'package:key_budget/features/documents/widgets/document_list_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'ENCRYPTION_KEY=12345678901234567890123456789012\n',
    );
  });

  group('DocumentExpiryHelper', () {
    final refDate = DateTime(2026, 9, 21);

    test('returns Validade não informada when expiry is null', () {
      final info = DocumentExpiryHelper.calculate(null, referenceDate: refDate);
      expect(info.label, 'Validade não informada');
      expect(info.variant, AppBadgeVariant.neutral);
    });

    test('returns Vencido for past dates', () {
      final pastDate = DateTime(2026, 9, 20);
      final info = DocumentExpiryHelper.calculate(pastDate, referenceDate: refDate);
      expect(info.label, 'Vencido');
      expect(info.variant, AppBadgeVariant.error);
    });

    test('returns Vence hoje for current civil date', () {
      final todayDate = DateTime(2026, 9, 21, 23, 59);
      final info = DocumentExpiryHelper.calculate(todayDate, referenceDate: refDate);
      expect(info.label, 'Vence hoje');
      expect(info.variant, AppBadgeVariant.warning);
    });

    test('returns singular Vence em 1 dia for tomorrow', () {
      final tomorrow = DateTime(2026, 9, 22);
      final info = DocumentExpiryHelper.calculate(tomorrow, referenceDate: refDate);
      expect(info.label, 'Vence em 1 dia');
      expect(info.variant, AppBadgeVariant.warning);
    });

    test('returns plural Vence em N dias for upcoming within 30 days', () {
      final future15 = DateTime(2026, 10, 6);
      final info = DocumentExpiryHelper.calculate(future15, referenceDate: refDate);
      expect(info.label, 'Vence em 15 dias');
      expect(info.variant, AppBadgeVariant.warning);
    });

    test('returns formatted date for dates beyond 30 days', () {
      final future60 = DateTime(2026, 11, 25);
      final info = DocumentExpiryHelper.calculate(future60, referenceDate: refDate);
      expect(info.label, 'Validade: 25/11/2026');
      expect(info.variant, AppBadgeVariant.neutral);
    });
  });

  group('Domain model copyWith nullification', () {
    test('Document copyWith supports clearing optional fields to null', () {
      final initialDoc = Document(
        id: 'doc_1',
        documentName: 'Passaporte',
        number: 'AB123456',
        issueDate: DateTime(2020, 1, 1),
        expiryDate: DateTime(2030, 1, 1),
        originalDocumentId: 'orig_1',
      );

      final updatedDoc = initialDoc.copyWith(
        clearNumber: true,
        clearIssueDate: true,
        clearExpiryDate: true,
        clearOriginalDocumentId: true,
      );

      expect(updatedDoc.number, isNull);
      expect(updatedDoc.issueDate, isNull);
      expect(updatedDoc.expiryDate, isNull);
      expect(updatedDoc.originalDocumentId, isNull);
      expect(updatedDoc.documentName, 'Passaporte');
    });

    test('Credential copyWith supports clearing optional fields to null', () {
      final initialCred = Credential(
        id: 'cred_1',
        location: 'Servidor',
        login: 'admin',
        encryptedPassword: 'enc',
        email: 'admin@example.com',
        phoneNumber: '11999999999',
        notes: 'Nota importante',
        logoPath: 'path/logo.png',
        folderId: 'folder_1',
      );

      final updatedCred = initialCred.copyWith(
        clearEmail: true,
        clearPhoneNumber: true,
        clearNotes: true,
        clearLogoPath: true,
        clearFolderId: true,
      );

      expect(updatedCred.email, isNull);
      expect(updatedCred.phoneNumber, isNull);
      expect(updatedCred.notes, isNull);
      expect(updatedCred.logoPath, isNull);
      expect(updatedCred.folderId, isNull);
      expect(updatedCred.location, 'Servidor');
    });
  });

  group('CredentialListTile widget presentation', () {
    testWidgets('never exposes password in list preview and has chevron', (tester) async {
      final cred = Credential(
        id: 'cred_preview',
        location: 'GitHub',
        login: 'user@example.com',
        encryptedPassword: 'my_secret_encrypted_payload',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CredentialListTile(credential: cred),
            ),
          ),
        ),
      );

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('my_secret_encrypted_payload'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });
  });

  group('DocumentListTile widget presentation', () {
    testWidgets('shows identity without attachment and expiry badges', (tester) async {
      final doc = Document(
        id: 'doc_1',
        documentName: 'Certidão',
        number: '12345',
        isPrincipal: true,
        expiryDate: null,
        attachments: [
          Attachment(name: 'certidao.pdf', type: 'pdf', driveId: 'drv1'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentListTile(doc: doc),
            ),
          ),
        ),
      );

      expect(find.text('Certidão'), findsOneWidget);
      expect(find.text('Nº: 12345'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Validade não informada'), findsNothing);
      expect(find.text('1 anexo'), findsNothing);
    });
  });

  group('CredentialDetailScreen security safeguards', () {
    testWidgets('starts with masked password, reveals on demand, and auto-hides', (tester) async {
      final encrypted = EncryptionService().encryptData('myPlainTextPassword');
      final cred = Credential(
        id: 'cred_detail',
        location: 'Portal Corporativo',
        login: 'colaborador',
        encryptedPassword: encrypted,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CredentialDetailScreen(credential: cred),
          ),
        ),
      );

      expect(find.text('Portal Corporativo'), findsWidgets);
      expect(find.text('colaborador'), findsOneWidget);
      expect(find.text('••••••••••••'), findsOneWidget);
      expect(find.byTooltip('Mostrar senha'), findsOneWidget);
      expect(find.byTooltip('Copiar senha'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pumpAndSettle();

      expect(find.text('myPlainTextPassword'), findsOneWidget);
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);

      await tester.tap(find.byTooltip('Ocultar senha'));
      await tester.pumpAndSettle();

      expect(find.text('••••••••••••'), findsOneWidget);
      expect(find.text('myPlainTextPassword'), findsNothing);
    });
  });
}
