import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import '../widgets/recipe_form.dart';
import '../widgets/common.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.recipe,
    required this.repository,
  });
  final Recipe recipe;
  final RecipeRepository repository;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _id;
  late Recipe _fallback;
  late final Stream<List<Recipe>> _recipes;
  bool _editing = false, _deleting = false, _renamed = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _id = widget.recipe.id;
    _fallback = widget.recipe;
    _recipes = widget.repository.watchRecipes(widget.recipe.userId);
  }

  Future<void> _delete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Remove “${recipe.name}” from your recipe box?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.repository.delete(recipe);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = 'Could not delete recipe. $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.recipe.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: SafeArea(
        child: StreamBuilder<List<Recipe>>(
          stream: _recipes,
          builder: (context, snapshot) {
            Recipe? recipe;
            for (final r in snapshot.data ?? <Recipe>[]) {
              if (r.id == _id) {
                recipe = r;
                break;
              }
            }
            if (recipe != null) {
              _fallback = recipe;
              _renamed = false;
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load this recipe. ${snapshot.error}'),
                ),
              );
            }
            if (recipe == null && snapshot.hasData && !_renamed && !_deleting) {
              return const Center(child: Text('This recipe no longer exists.'));
            }
            final current = recipe ?? _fallback;
            return SingleChildScrollView(
              key: const ValueKey('detail_scroll'),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_notice != null) ...[
                        Notice(
                          _notice!,
                          onDismiss: () => setState(() => _notice = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_error != null) ...[
                        Notice(_error!, error: true),
                        const SizedBox(height: 16),
                      ],
                      if (_editing)
                        ShelfCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Edit recipe',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 20),
                              RecipeForm(
                                key: ValueKey('edit_$_id'),
                                initialRecipe: current,
                                onCancel: () =>
                                    setState(() => _editing = false),
                                onSubmit: (draft) async {
                                  final nextId = await widget.repository.update(
                                    current,
                                    draft,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _renamed = nextId != _id;
                                    _id = nextId;
                                    _fallback = Recipe(
                                      id: nextId,
                                      userId: current.userId,
                                      name: draft.name.trim(),
                                      category: draft.category,
                                      difficulty: draft.difficulty,
                                      cookTime: draft.cookTime,
                                      servings: draft.servings,
                                      favorite: current.favorite,
                                      notes: draft.notes,
                                      createdAt: current.createdAt,
                                    );
                                    _editing = false;
                                    _notice = 'Recipe updated';
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Center(
                          child: RecipeArt(
                            category: current.category,
                            large: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                current.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('detail_favorite'),
                              tooltip: current.favorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              iconSize: 30,
                              onPressed: () async {
                                try {
                                  await widget.repository.toggleFavorite(
                                    current,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    setState(
                                      () => _error =
                                          'Could not update favorite. $e',
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                current.favorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xffb77d20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ShelfCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Field('Category', current.category),
                              _Field('Difficulty', current.difficulty),
                              _Field('Cook time', '${current.cookTime} min'),
                              _Field(
                                'Servings',
                                current.servings?.toString() ?? 'Not specified',
                              ),
                              _Field(
                                'Notes',
                                current.notes.isEmpty
                                    ? 'No notes yet.'
                                    : current.notes,
                                last: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('edit_recipe'),
                          onPressed: _deleting
                              ? null
                              : () => setState(() {
                                  _editing = true;
                                  _notice = null;
                                }),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const ValueKey('delete_recipe'),
                          onPressed: _deleting ? null : () => _delete(current),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.last = false});
  final String label, value;
  final bool last;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(letterSpacing: 1.3, color: const Color(0xff83776c)),
        ),
        const SizedBox(height: 5),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
