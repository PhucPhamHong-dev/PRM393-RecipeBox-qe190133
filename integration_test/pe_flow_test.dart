import 'package:recipebox/main.dart' as app;
import 'package:recipebox/models/recipe.dart';
import 'package:recipebox/services/recipe_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const email = String.fromEnvironment('TEST_EMAIL');
const password = String.fromEnvironment('TEST_PASSWORD');
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Complete RecipeBox exam flow against live Firebase', (
    tester,
  ) async {
    await app.main();
    await FirebaseAuth.instance.signOut();
    Future<void> waitFor(Finder f, {int seconds = 45}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (f.evaluate().isEmpty && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(f, findsWidgets);
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> tap(Finder f) async {
      await waitFor(f);
      await tester.ensureVisible(f.first);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(f.first);
      await tester.pump(const Duration(milliseconds: 450));
    }

    Future<void> enter(String key, String value) async {
      final f = find.byKey(ValueKey(key));
      await tester.ensureVisible(f);
      await tester.enterText(f, value);
      await tester.pump(const Duration(milliseconds: 400));
      final input = tester.widget(f);
      final controller = input is TextFormField
          ? input.controller
          : input is TextField
          ? input.controller
          : null;
      if (controller != null) {
        expect(
          controller.text == value,
          isTrue,
          reason: 'Input controller mismatch for $key',
        );
      }
    }

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot(name);
    }

    Future<void> top() async {
      final f = find.byKey(const ValueKey('list_scroll'));
      if (f.evaluate().isNotEmpty) {
        final s = tester.state<ScrollableState>(
          find.descendant(of: f, matching: find.byType(Scrollable)).first,
        );
        s.position.jumpTo(0);
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    Future<void> collection() async {
      await tester.ensureVisible(find.text('THE COLLECTION'));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> choose(String key, String value) async {
      await tap(find.byKey(ValueKey(key)));
      await tap(find.text(value).last);
    }

    Future<void> chooseFilter(String kind, String old, String next) async {
      await choose('filter_${kind}_$old', next);
    }

    await waitFor(find.text('Create your recipe box'));
    await binding.convertFlutterSurfaceToImage();
    await shot('01_home');
    await tester.ensureVisible(find.text('Mark your favorites'));
    await shot('01b_home_features');
    await tap(find.text('Register').first);
    await tap(find.byKey(const ValueKey('auth_submit')));
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    await shot('02_register_validation');
    await enter('auth_email', email);
    await enter('auth_password', password);
    await enter('auth_confirm', password);
    await tap(find.byKey(const ValueKey('auth_submit')));
    await waitFor(find.text('Registration successful'));
    await top();
    await shot('03_register_success');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = RecipeRepository(FirebaseFirestore.instance);
    const samples = [
      RecipeDraft(
        name: 'Omelette',
        category: 'Breakfast',
        difficulty: 'Easy',
        cookTime: 10,
        servings: 1,
        notes: 'A quick breakfast with fresh herbs.',
      ),
      RecipeDraft(
        name: 'Greek Salad',
        category: 'Lunch',
        difficulty: 'Easy',
        cookTime: 15,
        servings: 2,
        notes: 'Cucumber, feta and olives.',
      ),
      RecipeDraft(
        name: 'Pancakes',
        category: 'Breakfast',
        difficulty: 'Medium',
        cookTime: 15,
        servings: 3,
        notes: 'Serve warm with honey.',
      ),
      RecipeDraft(
        name: 'Chocolate Cake',
        category: 'Dessert',
        difficulty: 'Medium',
        cookTime: 45,
        servings: 8,
        notes: 'A rich dessert for sharing.',
      ),
      RecipeDraft(
        name: 'Pho Bo',
        category: 'Dinner',
        difficulty: 'Hard',
        cookTime: 60,
        servings: 4,
        notes: 'Finish with fresh BASIL and lime.',
      ),
    ];
    for (final s in samples) {
      await repo.add(uid, s);
    }
    var recipes = await repo.watchRecipes(uid).firstWhere((r) => r.length == 5);
    for (final r in recipes.where(
      (r) => ['Omelette', 'Pho Bo'].contains(r.name),
    )) {
      await repo.toggleFavorite(r);
    }
    await waitFor(find.text('Recipes: 5'));
    await waitFor(find.text('Total time: 145 min'));
    await tap(find.byKey(const ValueKey('logout')));
    await waitFor(find.text('Create your recipe box'));
    // Duplicate registration must display Firebase's refusal below the submit button.
    await tap(find.text('Register').first);
    await enter('auth_email', email);
    await enter('auth_password', password);
    await enter('auth_confirm', password);
    await tap(find.byKey(const ValueKey('auth_submit')));
    final duplicateAuth = find.byKey(const ValueKey('auth_server_error'));
    await waitFor(duplicateAuth);
    await shot('03b_duplicate_registration');
    await tap(find.byTooltip('Back'));
    await tap(find.text('Login').first);
    await shot('04_login');
    await enter('auth_email', email);
    await enter('auth_password', 'IncorrectPassword123!');
    await tap(find.byKey(const ValueKey('auth_submit')));
    await waitFor(find.byKey(const ValueKey('auth_server_error')));
    await shot('04b_login_error');
    await tap(find.byTooltip('Back'));
    await waitFor(find.text('Create your recipe box'));
    await tap(find.text('Login').first);
    await enter('auth_email', email);
    await enter('auth_password', password);
    await tap(find.byKey(const ValueKey('auth_submit')));
    await waitFor(find.text('Recipes: 5'));
    await waitFor(find.text('Favorites: 2'));
    await top();
    await shot('05_list_after_login');
    expect(
      Navigator.of(tester.element(find.text('Your recipe box'))).canPop(),
      isFalse,
    );
    await collection();
    await shot('06_cook_time_order');
    await top();
    await shot('07_summary');
    await enter('recipe_search', 'Tomato Soup');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 350));
    await tap(find.byKey(const ValueKey('add_recipe_expansion')));
    await tap(find.byKey(const ValueKey('recipe_submit')));
    for (final msg in [
      'Name is required',
      'Please choose a category',
      'Please choose a difficulty',
      'Cook time is required',
    ]) {
      expect(find.text(msg), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('recipe_name')));
    await shot('08_add_validation');
    await enter('recipe_name', 'Tomato Soup');
    await choose('recipe_category_add', 'Lunch');
    await choose('recipe_difficulty_add', 'Easy');
    await enter('recipe_cook_time', '20');
    await enter('recipe_servings', '2');
    await enter('recipe_notes', 'A rustic bowl of fresh tomato soup.');
    await tap(find.byKey(const ValueKey('recipe_submit')));
    await waitFor(find.text('Recipe added'));
    await waitFor(find.text('Tomato Soup'));
    await collection();
    await shot('09_add_success');
    await tap(find.byKey(const ValueKey('clear_filters')));
    await waitFor(find.text('Recipes: 6'));
    await waitFor(find.text('Total time: 165 min'));
    await collection();
    await shot('10_new_recipe_in_collection');
    await top();
    await chooseFilter('Category', 'All', 'Breakfast');
    await top();
    await shot('11_category_filter');
    expect(find.text('Recipes: 2'), findsOneWidget);
    expect(find.text('Total time: 25 min'), findsOneWidget);
    await chooseFilter('Difficulty', 'All', 'Easy');
    await top();
    await shot('12_difficulty_filter');
    expect(find.text('Recipes: 1'), findsOneWidget);
    await tap(find.byKey(const ValueKey('clear_filters')));
    await tap(find.byKey(const ValueKey('favorites_only')));
    await top();
    await shot('13_favorites_filter');
    expect(find.text('Recipes: 2'), findsOneWidget);
    expect(find.text('Total time: 70 min'), findsOneWidget);
    recipes = await repo.watchRecipes(uid).first;
    final omelette = recipes.singleWhere((r) => r.name == 'Omelette');
    await repo.toggleFavorite(omelette);
    await waitFor(find.text('Recipes: 1'));
    await shot('13b_unfavorite_removes_filtered');
    recipes = await repo.watchRecipes(uid).first;
    await repo.toggleFavorite(recipes.singleWhere((r) => r.name == 'Omelette'));
    await waitFor(find.text('Recipes: 2'));
    await chooseFilter('Category', 'All', 'Dinner');
    await chooseFilter('Difficulty', 'All', 'Hard');
    await enter('recipe_search', '  basil  ');
    await top();
    await shot('14_search_notes_combined');
    expect(find.text('Recipes: 1'), findsOneWidget);
    expect(find.text('Total time: 60 min'), findsOneWidget);
    await tap(find.byKey(const ValueKey('clear_filters')));
    await waitFor(find.text('Recipes: 6'));
    await collection();
    await tap(find.text('Pho Bo').last);
    await waitFor(find.text('Detail'));
    await shot('15_detail_view');
    await tap(find.byKey(const ValueKey('edit_recipe')));
    await enter('recipe_name', ' ');
    await enter('recipe_cook_time', '0');
    await enter('recipe_servings', '21');
    await tap(find.byKey(const ValueKey('recipe_submit')));
    await tester.ensureVisible(find.byKey(const ValueKey('recipe_name')));
    await shot('16_edit_validation');
    expect(find.text('Name is required'), findsOneWidget);
    expect(
      find.text('Cook time must be a whole number from 1 to 600'),
      findsOneWidget,
    );
    expect(
      find.text('Servings must be a whole number from 1 to 20'),
      findsOneWidget,
    );
    await enter('recipe_name', 'Pho Bo Express');
    await enter('recipe_cook_time', '12');
    await enter('recipe_servings', '2');
    await enter(
      'recipe_notes',
      'Updated note saved to Firestore with fresh basil.',
    );
    await tap(find.byKey(const ValueKey('recipe_submit')));
    await waitFor(find.text('Recipe updated'));
    await shot('17_detail_after_save');
    await tap(find.byKey(const ValueKey('edit_recipe')));
    await enter('recipe_name', 'Discarded edit');
    await tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await waitFor(find.text('Pho Bo Express'));
    expect(find.text('Discarded edit'), findsNothing);
    await tap(find.byKey(const ValueKey('detail_favorite')));
    await tester.pump(const Duration(seconds: 1));
    await shot('18_favorite_off');
    await tap(find.byKey(const ValueKey('detail_favorite')));
    await tester.pump(const Duration(seconds: 1));
    await shot('19_favorite_on');
    await tap(find.byTooltip('Back'));
    await waitFor(find.text('Recipes: 6'));
    await waitFor(find.text('Total time: 117 min'));
    await collection();
    await shot('19b_reordered_after_edit');
    recipes = await repo.watchRecipes(uid).first;
    final saved = recipes.singleWhere((r) => r.name == 'Pho Bo Express');
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(saved.id)
          .update({'cookTime': 601});
      fail('Live rules accepted cookTime 601');
    } on FirebaseException catch (e) {
      expect(e.code, 'permission-denied');
    }
    try {
      await repo.add(
        uid,
        const RecipeDraft(
          name: ' PHO BO EXPRESS ',
          category: 'Dinner',
          difficulty: 'Hard',
          cookTime: 12,
        ),
      );
      fail('Live duplicate accepted');
    } on FirebaseException catch (e) {
      expect(e.code, 'already-exists');
    }
    await tap(find.text('Tomato Soup').last);
    await waitFor(find.text('Detail'));
    await shot('20_before_delete');
    await tap(find.byKey(const ValueKey('delete_recipe')));
    await shot('21_delete_confirmation');
    await tap(find.widgetWithText(TextButton, 'Cancel'));
    await waitFor(find.text('Tomato Soup'));
    await tap(find.byKey(const ValueKey('delete_recipe')));
    await tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(find.text('Recipes: 5'));
    await waitFor(find.text('Total time: 97 min'));
    await collection();
    await shot('22_after_delete');
    expect(find.text('Tomato Soup'), findsNothing);
    await tap(find.byKey(const ValueKey('logout')));
    await waitFor(find.text('Create your recipe box'));
    await tap(find.text('Register').first);
    await enter('auth_email', 'empty.$email');
    await enter('auth_password', password);
    await enter('auth_confirm', password);
    await tap(find.byKey(const ValueKey('auth_submit')));
    await waitFor(find.text('No recipes found'));
    await top();
    await shot('23_second_account');
    await collection();
    await shot('24_empty_state');
    await tap(find.byKey(const ValueKey('logout')));
    await waitFor(find.text('Create your recipe box'));
    await tap(find.text('Login').first);
    await enter('auth_email', email);
    await enter('auth_password', password);
    await tap(find.byKey(const ValueKey('auth_submit')));
    await waitFor(find.text('Recipes: 5'));
    await waitFor(find.text('Favorites: 2'));
    await waitFor(find.text('Total time: 97 min'));
    await top();
    await shot('25_final_recipes');
    expect(tester.takeException(), isNull);
  });
}
