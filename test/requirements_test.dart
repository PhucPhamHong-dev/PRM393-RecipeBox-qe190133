import 'package:recipebox/models/recipe.dart';
import 'package:recipebox/screens/auth_screen.dart';
import 'package:recipebox/screens/home_screen.dart';
import 'package:recipebox/validators.dart';
import 'package:recipebox/widgets/recipe_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe recipe(
  String name,
  int minutes,
  String category, {
  String difficulty = 'Easy',
  bool favorite = false,
  String notes = '',
}) => Recipe(
  id: name,
  userId: 'alice',
  name: name,
  category: category,
  difficulty: difficulty,
  cookTime: minutes,
  favorite: favorite,
  notes: notes,
);
void main() {
  test('Canonical recipe ID normalizes case and outer spaces; owners stay separate', () {
    expect(
      canonicalRecipeId('a', ' Pho Bo '),
      canonicalRecipeId('a', 'pho bo'),
    );
    expect(
      canonicalRecipeId('a', 'Pho Bo'),
      isNot(canonicalRecipeId('b', 'Pho Bo')),
    );
    expect(canonicalRecipeId('a', 'A/B'), isNot(contains('/')));
  });
  test('Cook-time ordering and case-insensitive name tie break', () {
    final result = const RecipeFilter().apply([
      recipe('Z Soup', 25, 'Dinner'),
      recipe('apple pie', 25, 'Dessert'),
      recipe('Eggs', 5, 'Breakfast'),
    ]);
    expect(result.map((r) => r.name), ['Eggs', 'apple pie', 'Z Soup']);
  });
  test(
    'All filters combine and trimmed case-insensitive search checks notes',
    () {
      final recipes = [
        recipe(
          'Pho Bo',
          60,
          'Dinner',
          difficulty: 'Medium',
          favorite: true,
          notes: 'Fresh BASIL',
        ),
        recipe('Soup', 20, 'Lunch', favorite: true, notes: 'basil'),
        recipe('Rice', 10, 'Dinner', difficulty: 'Medium', notes: 'basil'),
      ];
      final visible = const RecipeFilter(
        category: 'Dinner',
        difficulty: 'Medium',
        favoritesOnly: true,
        search: ' BASIL ',
      ).apply(recipes);
      expect(visible.single.name, 'Pho Bo');
      expect(
        const RecipeFilter(search: ' pho ').apply(recipes).single.name,
        'Pho Bo',
      );
      expect(const RecipeFilter(category: 'Dessert').apply(recipes), isEmpty);
    },
  );
  test(
    'Summary reflects visible recipes with total time and category tie order',
    () {
      final result = RecipeSummary([
        recipe('A', 10, 'Dessert'),
        recipe('B', 20, 'Lunch', favorite: true),
        recipe('C', 30, 'Breakfast'),
        recipe('D', 40, 'Lunch'),
      ]);
      expect(result.count, 4);
      expect(result.favorites, 1);
      expect(result.totalTime, 100);
      expect(result.categoryCounts.keys, ['Lunch', 'Breakfast', 'Dessert']);
      final empty = RecipeSummary([]);
      expect(empty.count, 0);
      expect(empty.totalTime, 0);
      expect(empty.categoryCounts, isEmpty);
    },
  );
  test('Validation exact messages and required numeric boundaries', () {
    expect(Validators.email(''), 'Email is required');
    expect(Validators.email('a@'), 'Please enter a valid email address');
    expect(Validators.password(''), 'Password is required');
    expect(
      Validators.password('12345', register: true),
      'Password must be at least 6 characters',
    );
    expect(Validators.password('1'), isNull);
    expect(
      Validators.confirmPassword('', '123456'),
      'Confirm password is required',
    );
    expect(
      Validators.confirmPassword('123457', '123456'),
      'Passwords do not match',
    );
    expect(Validators.name(' \t '), 'Name is required');
    expect(Validators.name('a' * 80), isNull);
    expect(Validators.name('a' * 81), 'Name must be at most 80 characters');
    expect(Validators.category(null), 'Please choose a category');
    expect(Validators.difficulty(''), 'Please choose a difficulty');
    expect(Validators.cookTime(''), 'Cook time is required');
    for (final v in ['0', '601', '1.2', '-1', 'abc', '1e2']) {
      expect(
        Validators.cookTime(v),
        'Cook time must be a whole number from 1 to 600',
      );
    }
    for (final v in ['1', '600']) {
      expect(Validators.cookTime(v), isNull);
    }
    expect(Validators.servings(''), isNull);
    for (final v in ['0', '21', '1.2', 'abc']) {
      expect(
        Validators.servings(v),
        'Servings must be a whole number from 1 to 20',
      );
    }
    for (final v in ['1', '20']) {
      expect(Validators.servings(v), isNull);
    }
    expect(Validators.notes('a' * 300), isNull);
    expect(Validators.notes('a' * 301), 'Notes must be at most 300 characters');
  });
  testWidgets(
    'Register hides initial errors and removes a corrected field error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AuthScreen(register: true, onRegistered: () {})),
      );
      expect(find.text('Email is required'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('auth_submit')));
      await tester.tap(find.byKey(const ValueKey('auth_submit')));
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Confirm password is required'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth_email')),
        'reader@example.com',
      );
      await tester.pump();
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsOneWidget);
    },
  );
  testWidgets(
    'Add Recipe validates only after submit and clears corrected name error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecipeForm(onSubmit: (_) async {}),
            ),
          ),
        ),
      );
      expect(find.text('Name is required'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('recipe_submit')));
      await tester.tap(find.byKey(const ValueKey('recipe_submit')));
      await tester.pump();
      for (final msg in [
        'Name is required',
        'Please choose a category',
        'Please choose a difficulty',
        'Cook time is required',
      ]) {
        expect(find.text(msg), findsOneWidget);
      }
      await tester.enterText(
        find.byKey(const ValueKey('recipe_name')),
        'Pho Bo',
      );
      await tester.pump();
      expect(find.text('Name is required'), findsNothing);
      expect(find.text('Cook time is required'), findsOneWidget);
    },
  );
  testWidgets('Home fits 320-pixel phone and contains three features', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(onLogin: () {}, onRegister: () {}),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('RecipeBox'), findsWidgets);
  });
}
