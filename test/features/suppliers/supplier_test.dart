import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/credentials/widgets/saved_logos_screen.dart';
import 'package:key_budget/features/suppliers/repository/supplier_repository.dart';
import 'package:key_budget/features/suppliers/view/add_supplier_screen.dart';
import 'package:key_budget/features/suppliers/view/suppliers_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:key_budget/features/suppliers/widgets/supplier_form.dart';
import 'package:key_budget/features/suppliers/widgets/supplier_preview_panel.dart';

class FakeSupplierRepository extends Fake implements SupplierRepository {}

class FakeCredentialRepository extends Fake implements CredentialRepository {}

class FakeAuthRepository extends Fake implements AuthRepository {}

class FakeSupplierViewModel extends SupplierViewModel {
  FakeSupplierViewModel({List<Supplier>? suppliers}) : super(repository: FakeSupplierRepository()) {
    setSuppliersForTesting(suppliers ?? [
    Supplier(
      id: 's1',
      name: 'Fornecedor A',
      photoPath: 'photo_supplier_a',
    ),
    ]);
  }

  @override
  void listenToSuppliers(String userId) {}

  @override
  List<String> get userSupplierPhotos =>
      ['photo_supplier_a', 'photo_supplier_a', ''];
}

class FakeCredentialViewModel extends CredentialViewModel {
  FakeCredentialViewModel() : super(repository: FakeCredentialRepository());

  @override
  List<String> get userCredentialLogos => ['logo_credential_1'];
}

class FakeAuthViewModel extends AuthViewModel {
  FakeAuthViewModel()
      : super(
          authRepository: FakeAuthRepository(),
          listenToAuthChanges: false,
        );

  @override
  User? get currentUser => User(
        id: 'test_uid',
        name: 'Tester',
        email: 'tester@test.com',
      );
}

void main() {
  testWidgets('AddSupplierScreen renders SupplierForm with isEditing true', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith((ref) => FakeAuthViewModel()),
          supplierViewModelProvider.overrideWith((ref) => FakeSupplierViewModel()),
        ],
        child: const MaterialApp(
          home: AddSupplierScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final formFinder = find.byType(SupplierForm);
    expect(formFinder, findsOneWidget);
    final formWidget = tester.widget<SupplierForm>(formFinder);
    expect(formWidget.isEditing, isTrue);

    final nameField =
        find.widgetWithText(AppTextField, 'Nome do Fornecedor / Loja *');
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Distribuidora Silva');
    expect(find.text('Distribuidora Silva'), findsOneWidget);
    await tester.pump();

    final popScope = tester.widget<PopScope>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    expect(popScope.canPop, isFalse);
    popScope.onPopInvokedWithResult!(false, null);
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AddSupplierScreen), findsOneWidget);
  });

  testWidgets('AppTextField advances focus when keyboard action is next', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AppTextField(label: 'Primeiro', textInputAction: TextInputAction.next),
            AppTextField(label: 'Segundo', textInputAction: TextInputAction.done),
          ],
        ),
      ),
    ));

    await tester.tap(find.widgetWithText(AppTextField, 'Primeiro'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText).at(1)).focusNode.hasFocus, isTrue);
  });

  testWidgets('SuppliersScreen shows list and selected detail on tablet', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = FakeSupplierViewModel(suppliers: [
      Supplier(id: 's1', name: 'Fornecedor A'),
      Supplier(id: 's2', name: 'Fornecedor B', email: 'b@exemplo.com'),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith((ref) => FakeAuthViewModel()),
        supplierViewModelProvider.overrideWith((ref) => vm),
      ],
      child: const MaterialApp(home: SuppliersScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SupplierPreviewPanel), findsOneWidget);
    expect(tester.widget<SupplierPreviewPanel>(find.byType(SupplierPreviewPanel)).supplier.name, 'Fornecedor A');
    await tester.tap(find.text('Fornecedor B').first);
    await tester.pumpAndSettle();
    expect(tester.widget<SupplierPreviewPanel>(find.byType(SupplierPreviewPanel)).supplier.name, 'Fornecedor B');
  });

  testWidgets('SupplierForm places paired fields in columns on tablet', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith((ref) => FakeAuthViewModel()),
        supplierViewModelProvider.overrideWith((ref) => FakeSupplierViewModel()),
      ],
      child: const MaterialApp(home: AddSupplierScreen()),
    ));
    await tester.pumpAndSettle();

    final name = tester.getTopLeft(find.widgetWithText(AppTextField, 'Nome do Fornecedor / Loja *'));
    final representative = tester.getTopLeft(find.widgetWithText(AppTextField, 'Nome do Representante'));
    expect(name.dy, representative.dy);
    expect(representative.dx, greaterThan(name.dx));
  });

  testWidgets('SavedLogosScreen filters photos by module and deduplicates', (tester) async {

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierViewModelProvider.overrideWith((ref) => FakeSupplierViewModel()),
          credentialViewModelProvider.overrideWith((ref) => FakeCredentialViewModel()),
        ],
        child: const MaterialApp(
          home: SavedLogosScreen(isForSuppliers: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierViewModelProvider.overrideWith((ref) => FakeSupplierViewModel()),
          credentialViewModelProvider.overrideWith((ref) => FakeCredentialViewModel()),
        ],
        child: const MaterialApp(
          home: SavedLogosScreen(isForSuppliers: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsOneWidget);
  });
}
