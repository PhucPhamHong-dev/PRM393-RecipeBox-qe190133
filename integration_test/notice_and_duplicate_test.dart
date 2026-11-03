import 'package:recipebox/main.dart' as app;
import 'package:recipebox/services/recipe_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Live duplicate rejection and add-notice lifecycle regression', (
    tester,
  ) async {
    await app.main();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: const String.fromEnvironment('TEST_EMAIL'),
      password: const String.fromEnvironment('TEST_PASSWORD'),
    );
    Future<void> wait(Finder finder) async {
      final end = DateTime.now().add(const Duration(seconds: 45));
      while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(finder, findsWidgets);
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> settle() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> tap(Finder f) async {
      await wait(f);
      await settle();
      await tester.ensureVisible(f.first);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(f.first);
      await tester.pump(const Duration(milliseconds: 450));
    }

    Future<void> enter(String key, String value) async {
      final f = find.byKey(ValueKey(key));
      await tester.ensureVisible(f);
      await tester.enterText(f, value);
      await tester.pump(const Duration(milliseconds: 200));
      final input = tester.widget(f);
      final controller = input is TextFormField
          ? input.controller
          : (input as TextField).controller;
      expect(
        controller!.text,
        value,
        reason: "Input must be replaced before submitting",
      );
    }

    Future<void> choose(String key, String value) async {
      await tap(find.byKey(ValueKey(key)));
      await tap(find.text(value).last);
    }

    ScrollPosition listPosition() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const ValueKey('list_scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    Future<void> top() async {
      listPosition().jumpTo(0);
      await settle();
    }

    Future<void> fit(String name) async {
      await settle();
      final card = find
          .ancestor(of: find.text(name).last, matching: find.byType(Card))
          .first;
      final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final p = listPosition();
      final d = (tester.getRect(card).bottom - h + 30).clamp(
        0.0,
        p.maxScrollExtent,
      );
      p.jumpTo((p.pixels + d).clamp(0.0, p.maxScrollExtent));
      await settle();
      expect(tester.getRect(card).bottom, lessThan(h - 15));
    }

    Future<void> shot(String name) async {
      await settle();
      await binding.takeScreenshot(name);
    }

    Future<void> draft(String name) async {
      await enter('recipe_name', name);
      await choose('recipe_category_add', 'Lunch');
      await choose('recipe_difficulty_add', 'Easy');
      await enter('recipe_cook_time', '20');
      await enter('recipe_servings', '2');
      await enter('recipe_notes', 'A rustic bowl of fresh tomato soup.');
    }

    final repo = RecipeRepository(FirebaseFirestore.instance);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await wait(find.text('Recipes: 5'));
    final original = await repo.watchRecipes(uid).first;
    final originalIds = original.map((r) => r.id).toSet();
    expect(original.length, 5);
    expect(original.any((r) => r.name == 'Pho Bo Express'), isTrue);
    await binding.convertFlutterSurfaceToImage();
    await top();
    await fit('Pho Bo Express');
    await shot('32_duplicate_before');
    await tap(find.byKey(const ValueKey('add_recipe_expansion')));
    await draft('pHo bO eXpReSs');
    await tap(find.byKey(const ValueKey('recipe_submit')));
    final error = find.byKey(const ValueKey('recipe_server_error'));
    await wait(error);
    expect(
      find.text('A recipe with this name already exists.'),
      findsOneWidget,
    );
    final afterDuplicate = await repo.watchRecipes(uid).first;
    expect(afterDuplicate.map((r) => r.id).toSet(), originalIds);
    expect(afterDuplicate.length, 5);
    expect(find.text('Recipes: 5'), findsOneWidget);
    await tester.ensureVisible(error);
    await settle();
    // Keep both the attempted mixed-case name and the error below Add Recipe in view.
    final nameField = find.byKey(const ValueKey('recipe_name'));
    final position = listPosition();
    position.jumpTo(
      (position.pixels + tester.getRect(nameField).top - 100).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
    await settle();
    expect(tester.getRect(nameField).top, greaterThan(75));
    expect(
      tester.getRect(error).bottom,
      lessThan(
        tester.view.physicalSize.height / tester.view.devicePixelRatio - 20,
      ),
    );
    await shot('33_duplicate_rejected_form');
    await tap(find.byKey(const ValueKey('add_recipe_expansion')));
    await top();
    await fit('Pho Bo Express');
    await shot('34_duplicate_unchanged_list');
    // A genuine successful add supplies a live notice for navigation regression.
    await enter('recipe_search', 'Tomato Soup');
    await settle();
    await tap(find.byKey(const ValueKey('add_recipe_expansion')));
    await enter('recipe_name', 'Tomato Soup');
    await tap(find.byKey(const ValueKey('recipe_submit')));
    await wait(find.text('Recipe added'));
    await wait(find.text('Tomato Soup'));
    await fit('Tomato Soup');
    await shot('09_add_success');
    await tap(find.text('Tomato Soup').last);
    await wait(find.byKey(const ValueKey('edit_recipe')));
    await tap(find.byKey(const ValueKey('edit_recipe')));
    await enter('recipe_notes', 'A rustic bowl of fresh tomato soup.');
    await tap(find.byKey(const ValueKey('recipe_submit')));
    await wait(find.text('Recipe updated'));
    await tap(find.byTooltip('Back'));
    await wait(find.byKey(const ValueKey('list_scroll')));
    expect(
      find.text('Recipe added'),
      findsNothing,
      reason: 'Add notice must not survive editing in Detail',
    );
    await tap(find.byKey(const ValueKey('clear_filters')));
    await wait(find.text('Recipes: 6'));
    expect(find.text('Total time: 117 min'), findsOneWidget);
    await fit('Chocolate Cake');
    await shot('19b_reordered_after_edit');
    await shot('10_new_recipe_in_collection');
    await tap(find.text('Tomato Soup').last);
    await wait(find.byKey(const ValueKey('delete_recipe')));
    await shot('20_before_delete');
    await tap(find.byKey(const ValueKey('delete_recipe')));
    await shot('21_delete_confirmation');
    await tap(find.widgetWithText(FilledButton, 'Delete'));
    await wait(find.text('Recipes: 5'));
    await settle();
    expect(
      find.text('Recipe added'),
      findsNothing,
      reason: 'Add notice must not survive deletion',
    );
    expect(find.text('Tomato Soup'), findsNothing);
    final finalRecipes = await repo
        .watchRecipes(uid)
        .firstWhere((r) => r.length == 5);
    expect(finalRecipes.map((r) => r.id).toSet(), originalIds);
    expect(find.text('Total time: 97 min'), findsOneWidget);
    await fit('Chocolate Cake');
    await shot('22_after_delete');
    // Refresh old filtered evidence from the fixed build as well.
    await choose('filter_Category_All', 'Breakfast');
    await choose('filter_Difficulty_All', 'Easy');
    await top();
    await fit('Omelette');
    await shot('12_difficulty_filter');
    await tap(find.byKey(const ValueKey('clear_filters')));
    await tap(find.byKey(const ValueKey('favorites_only')));
    await top();
    await fit('Pho Bo Express');
    await shot('13_favorites_filter');
    final omelette = find
        .ancestor(of: find.text('Omelette').last, matching: find.byType(Card))
        .first;
    await tap(find.descendant(of: omelette, matching: find.byType(IconButton)));
    await wait(find.text('Recipes: 1'));
    expect(find.text('Omelette'), findsNothing);
    await top();
    await fit('Pho Bo Express');
    await shot('13b_unfavorite_removes_filtered');
    final now = await repo.watchRecipes(uid).first;
    await repo.toggleFavorite(now.singleWhere((r) => r.name == 'Omelette'));
    await tap(find.byKey(const ValueKey('clear_filters')));
    await wait(find.text('Recipes: 5'));
    expect(find.text('Favorites: 2'), findsOneWidget);
    expect(find.text('Total time: 97 min'), findsOneWidget);
    expect(find.text('Recipe added'), findsNothing);
    await top();
    await shot('25_final_recipes');
  });
}
