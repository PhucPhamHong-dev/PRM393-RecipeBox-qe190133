import 'package:flutter/material.dart';

import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'RecipeBox',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(onPressed: onLogin, child: const Text('Login')),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: onRegister,
            child: const Text('Register'),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'GOOD FOOD. YOUR WAY.',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: recipeAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RecipeBox',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'A little inspiration.\nSomething delicious.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep your favorite recipes and the meals you want to try in one private collection. Find your next dish in a moment.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0e7d8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          RecipeArt(category: 'Breakfast'),
                          RecipeArt(category: 'Lunch'),
                          RecipeArt(category: 'Dessert'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'From quick bites to\nweekend favorites.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create your recipe box'),
                ),
                const SizedBox(height: 22),
                const _Feature(
                  icon: Icons.menu_book_outlined,
                  title: 'Save your recipes',
                  description:
                      'Your own collection, securely saved to your account.',
                ),
                const SizedBox(height: 10),
                const _Feature(
                  icon: Icons.timer_outlined,
                  title: 'Sort by cooking time',
                  description:
                      'Find a quick meal or make time for something special.',
                ),
                const SizedBox(height: 10),
                const _Feature(
                  icon: Icons.star_outline_rounded,
                  title: 'Mark your favorites',
                  description: 'Keep the dishes you love close at hand.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => ShelfCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: recipeAccent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
      ],
    ),
  );
}
