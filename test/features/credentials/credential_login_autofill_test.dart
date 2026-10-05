import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/features/credentials/domain/credential_login_autofill.dart';

void main() {
  test('Reconhece somente email completo', () {
    expect(
      CredentialLoginAutofill.email(' pessoa@exemplo.com '),
      'pessoa@exemplo.com',
    );
    expect(CredentialLoginAutofill.email('pessoa@exemplo'), isNull);
    expect(CredentialLoginAutofill.email('pessoa@exemplo.com texto'), isNull);
  });

  test('Não interpreta CPF nem sequência numérica como telefone', () {
    expect(CredentialLoginAutofill.phone('123.456.789-09'), isNull);
    expect(CredentialLoginAutofill.phone('12345678909'), isNull);
    expect(CredentialLoginAutofill.phone('11987654321'), isNull);
    expect(CredentialLoginAutofill.phone('1234567890'), isNull);
  });

  test('Reconhece telefone quando há formato explícito com DDD', () {
    expect(CredentialLoginAutofill.phone('(11) 98765-4321'), '11987654321');
    expect(CredentialLoginAutofill.phone('11 3456-7890'), '1134567890');
    expect(CredentialLoginAutofill.phone('(11) 3456-7890'), '1134567890');
  });
}
