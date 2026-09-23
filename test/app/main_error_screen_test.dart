import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/main.dart';

void main() {
  testWidgets('startup error offers a safe retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(ErrorScreen(onRetry: () => retries++));

    expect(find.text('Não foi possível iniciar o KeyBudget'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
  });
}
