import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'unicode_casefold.dart';
export 'unicode_casefold.dart' show canonicalRecipeName;

const recipeCategories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
const recipeDifficulties = ['Easy', 'Medium', 'Hard'];
String canonicalRecipeId(String userId, String name) =>
    '${userId}_${sha256.convert(utf8.encode(canonicalRecipeName(name)))}';

class Recipe {
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.favorite = false,
    this.notes = '',
    this.createdAt,
  });
  final String id, userId, name, category, difficulty, notes;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final DateTime? createdAt;
  factory Recipe.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Recipe(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      category: d['category'] as String,
      difficulty: d['difficulty'] as String,
      cookTime: (d['cookTime'] as num).toInt(),
      servings: (d['servings'] as num?)?.toInt(),
      favorite: d['favorite'] as bool? ?? false,
      notes: d['notes'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'name': name,
    'nameKey': canonicalRecipeName(name),
    'category': category,
    'difficulty': difficulty,
    'cookTime': cookTime,
    'servings': servings,
    'favorite': favorite,
    'notes': notes,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };
}

class RecipeDraft {
  const RecipeDraft({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.notes = '',
  });
  final String name, category, difficulty, notes;
  final int cookTime;
  final int? servings;
}

class RecipeFilter {
  const RecipeFilter({
    this.category = 'All',
    this.difficulty = 'All',
    this.favoritesOnly = false,
    this.search = '',
  });
  final String category, difficulty, search;
  final bool favoritesOnly;
  List<Recipe> apply(Iterable<Recipe> recipes) {
    final q = search.trim().toLowerCase();
    final result = recipes
        .where(
          (r) =>
              (category == 'All' || r.category == category) &&
              (difficulty == 'All' || r.difficulty == difficulty) &&
              (!favoritesOnly || r.favorite) &&
              (q.isEmpty ||
                  r.name.toLowerCase().contains(q) ||
                  r.notes.toLowerCase().contains(q)),
        )
        .toList();
    result.sort((a, b) {
      final t = a.cookTime.compareTo(b.cookTime);
      if (t != 0) return t;
      final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return n != 0 ? n : a.id.compareTo(b.id);
    });
    return result;
  }
}

List<MapEntry<String, int>> categoryBreakdown(Iterable<Recipe> recipes) {
  final counts = <String, int>{};
  for (final r in recipes) {
    counts.update(r.category, (n) => n + 1, ifAbsent: () => 1);
  }
  final rows = counts.entries.toList();
  rows.sort((a, b) {
    final c = b.value.compareTo(a.value);
    return c != 0
        ? c
        : recipeCategories
              .indexOf(a.key)
              .compareTo(recipeCategories.indexOf(b.key));
  });
  return rows;
}

class RecipeSummary {
  RecipeSummary(Iterable<Recipe> recipes) {
    final rows = recipes.toList();
    count = rows.length;
    favorites = rows.where((r) => r.favorite).length;
    totalTime = rows.fold(0, (total, r) => total + r.cookTime);
    categoryCounts = Map.fromEntries(categoryBreakdown(rows));
  }
  late final int count, favorites, totalTime;
  late final Map<String, int> categoryCounts;
}
