import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/widgets/animated_item_sliver.dart';

void main() {
  Widget buildList(List<String> items) => MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          AnimatedItemSliver<String>(
            items: items,
            identity: (item) => item,
            itemBuilder: (_, item) =>
                ListTile(key: ValueKey(item), title: Text(item)),
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'list keeps item identities across removal, insertion and reorder',
    (tester) async {
      await tester.pumpWidget(buildList(['A', 'B', 'C']));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildList(['C', 'A', 'D']));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
