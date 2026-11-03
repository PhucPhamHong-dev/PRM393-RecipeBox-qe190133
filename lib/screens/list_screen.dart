import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import '../widgets/recipe_form.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.user,
    required this.repository,
    this.registrationMessage,
  });
  final User user;
  final RecipeRepository repository;
  final String? registrationMessage;
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();
  final _addController = ExpansibleController();
  late final Stream<List<Recipe>> _recipes;
  String _category = 'All', _difficulty = 'All';
  bool _favoritesOnly = false;
  String? _notice, _error;
  bool _added = false;
  @override
  void initState() {
    super.initState();
    _recipes = widget.repository.watchRecipes(widget.user.uid);
    _notice = widget.registrationMessage;
  }

  @override
  void didUpdateWidget(covariant ListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.registrationMessage != oldWidget.registrationMessage &&
        widget.registrationMessage != null) {
      _notice = widget.registrationMessage;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    setState(() {
      _category = 'All';
      _difficulty = 'All';
      _favoritesOnly = false;
    });
  }

  Future<void> _favorite(Recipe r) async {
    try {
      await widget.repository.toggleFavorite(r);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not update favorite. $e');
    }
  }

  Widget _filter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('filter_${label}_$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    items: [
      'All',
      ...options,
    ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: (v) {
      if (v != null) setState(() => changed(v));
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List'),
          Text(
            widget.user.email ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          key: const ValueKey('logout'),
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signOut();
            } catch (e) {
              if (mounted) setState(() => _error = 'Could not log out. $e');
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Logout'),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: SafeArea(
      child: StreamBuilder<List<Recipe>>(
        stream: _recipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Notice(
                  'Could not load recipes. ${snapshot.error}',
                  error: true,
                ),
              ),
            );
          }
          final visible = RecipeFilter(
            category: _category,
            difficulty: _difficulty,
            favoritesOnly: _favoritesOnly,
            search: _search.text,
          ).apply(snapshot.data ?? []);
          return SingleChildScrollView(
            key: const ValueKey('list_scroll'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu_rounded,
                          color: recipeAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your recipe box',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Text('Good things are cooking.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_notice != null) ...[
                      Notice(
                        _notice!,
                        onDismiss: () => setState(() => _notice = null),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      Notice(
                        _error!,
                        error: true,
                        onDismiss: () => setState(() => _error = null),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _Summary(recipes: visible),
                    const SizedBox(height: 14),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        key: const ValueKey('add_recipe_expansion'),
                        controller: _addController,
                        maintainState: true,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: const Icon(Icons.add_circle_outline_rounded),
                        title: const Text('Add Recipe'),
                        subtitle: const Text('A new dish for your collection'),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          18,
                          4,
                          18,
                          20,
                        ),
                        children: [
                          RecipeForm(
                            onSubmit: (draft) =>
                                widget.repository.add(widget.user.uid, draft),
                            onSuccess: () {
                              setState(() => _added = true);
                              _addController.collapse();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ShelfCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Find a recipe',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('clear_filters'),
                                onPressed: _clear,
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            key: const ValueKey('recipe_search'),
                            controller: _search,
                            decoration: const InputDecoration(
                              labelText: 'Search name or notes',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, c) {
                              final f = [
                                _filter(
                                  'Category',
                                  _category,
                                  recipeCategories,
                                  (v) => _category = v,
                                ),
                                _filter(
                                  'Difficulty',
                                  _difficulty,
                                  recipeDifficulties,
                                  (v) => _difficulty = v,
                                ),
                              ];
                              return c.maxWidth < 290
                                  ? Column(
                                      children: [
                                        f[0],
                                        const SizedBox(height: 14),
                                        f[1],
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: f[0]),
                                        const SizedBox(width: 12),
                                        Expanded(child: f[1]),
                                      ],
                                    );
                            },
                          ),
                          SwitchListTile.adaptive(
                            key: const ValueKey('favorites_only'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Favorites only'),
                            value: _favoritesOnly,
                            onChanged: (v) =>
                                setState(() => _favoritesOnly = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'THE COLLECTION',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(letterSpacing: 1.5),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color(0xff81776e),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quickest first',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_added) ...[
                      Notice(
                        'Recipe added',
                        onDismiss: () => setState(() => _added = false),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (visible.isEmpty)
                      const ShelfCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 26),
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu_outlined,
                                size: 38,
                                color: Color(0xff9a8a78),
                              ),
                              SizedBox(height: 12),
                              Text('No recipes found'),
                            ],
                          ),
                        ),
                      ),
                    for (final recipe in visible) ...[
                      Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailScreen(
                                recipe: recipe,
                                repository: widget.repository,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RecipeArt(category: recipe.category),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 5,
                                        children: [
                                          _Tag(recipe.category),
                                          _Tag(recipe.difficulty),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule_rounded,
                                            size: 15,
                                            color: recipeAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${recipe.cookTime} min',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: recipeAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('favorite_${recipe.id}'),
                                  tooltip: recipe.favorite
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                  onPressed: () => _favorite(recipe),
                                  icon: Icon(
                                    recipe.favorite
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: recipe.favorite
                                        ? const Color(0xffb77d20)
                                        : const Color(0xff827b70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xfff1ece3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: Color(0xff6b6559)),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.recipes});
  final List<Recipe> recipes;
  @override
  Widget build(BuildContext context) {
    final s = RecipeSummary(recipes);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recipeAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 5,
              children: [
                Text(
                  'Recipes: ${s.count}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Favorites: ${s.favorites}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total time: ${s.totalTime} min',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (s.categoryCounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final e in s.categoryCounts.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      Text('${e.value}'),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
