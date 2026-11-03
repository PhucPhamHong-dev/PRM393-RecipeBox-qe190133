import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

class RecipeRepository {
  RecipeRepository(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> get _recipes =>
      firestore.collection('recipes');
  Stream<List<Recipe>> watchRecipes(String userId) => _recipes
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(Recipe.fromDocument).toList());
  Future<void> add(String userId, RecipeDraft draft) async {
    final id = canonicalRecipeId(userId, draft.name);
    final ref = _recipes.doc(id);
    await firestore.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A recipe with this name already exists.',
        );
      }
      tx.set(
        ref,
        Recipe(
          id: id,
          userId: userId,
          name: draft.name.trim(),
          category: draft.category,
          difficulty: draft.difficulty,
          cookTime: draft.cookTime,
          servings: draft.servings,
          notes: draft.notes,
        ).toFirestore(),
      );
    });
  }

  Future<String> update(Recipe original, RecipeDraft draft) async {
    final id = canonicalRecipeId(original.userId, draft.name);
    final oldRef = _recipes.doc(original.id), newRef = _recipes.doc(id);
    await firestore.runTransaction((tx) async {
      final current = await tx.get(oldRef);
      if (!current.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'This recipe no longer exists.',
        );
      }
      if (id != original.id && (await tx.get(newRef)).exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A recipe with this name already exists.',
        );
      }
      tx.set(newRef, {
        ...current.data()!,
        'id': id,
        'name': draft.name.trim(),
        'nameKey': canonicalRecipeName(draft.name),
        'category': draft.category,
        'difficulty': draft.difficulty,
        'cookTime': draft.cookTime,
        'servings': draft.servings,
        'notes': draft.notes,
      });
      if (id != original.id) tx.delete(oldRef);
    });
    return id;
  }

  Future<void> toggleFavorite(Recipe recipe) =>
      _recipes.doc(recipe.id).update({'favorite': !recipe.favorite});
  Future<void> delete(Recipe recipe) => _recipes.doc(recipe.id).delete();
}
