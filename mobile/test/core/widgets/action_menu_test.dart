import 'package:cocotte_minute/core/widgets/action_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Monte un bouton qui ouvre le menu « … » ; renvoie le contexte du bouton
  /// via un Builder (ancrage) comme dans les écrans réels.
  Future<void> pumpMenuHost(
    WidgetTester tester,
    List<ActionMenuItem> items,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showActionMenu(context: context, items: items),
                ),
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
  }

  testWidgets('affiche les entrées puis exécute l\'action et se referme',
      (tester) async {
    var selected = 0;
    await pumpMenuHost(tester, [
      ActionMenuItem(
        icon: Icons.shopping_cart_outlined,
        label: 'Ajouter aux courses',
        style: ActionMenuStyle.primary,
        onSelected: () => selected++,
      ),
      ActionMenuItem(
        icon: Icons.edit_outlined,
        label: 'Modifier',
        onSelected: () {},
      ),
      ActionMenuItem(
        icon: Icons.delete_outline_rounded,
        label: 'Supprimer',
        style: ActionMenuStyle.destructive,
        dividerBefore: true,
        onSelected: () {},
      ),
    ]);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter aux courses'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);

    await tester.tap(find.text('Ajouter aux courses'));
    await tester.pumpAndSettle();

    // L'action s'exécute et le popover se referme.
    expect(selected, 1);
    expect(find.text('Modifier'), findsNothing);
  });

  testWidgets('un tap sur le scrim referme le menu sans action', (tester) async {
    var selected = 0;
    await pumpMenuHost(tester, [
      ActionMenuItem(
        icon: Icons.edit_outlined,
        label: 'Modifier',
        onSelected: () => selected++,
      ),
    ]);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Modifier'), findsOneWidget);

    // Tap en haut à gauche (hors popover, sur le scrim).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsNothing);
    expect(selected, 0);
  });
}
