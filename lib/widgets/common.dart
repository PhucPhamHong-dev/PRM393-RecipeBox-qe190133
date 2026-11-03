import 'package:flutter/material.dart';

const recipeAccent = Color(0xffb44d32);

class ShelfCard extends StatelessWidget {
  const ShelfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: padding, child: child),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.onDismiss, this.error = false});
  final String message;
  final VoidCallback? onDismiss;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
    decoration: BoxDecoration(
      color: error ? const Color(0xffffecea) : const Color(0xffedf2e7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(
          error ? Icons.error_outline : Icons.check_circle_outline,
          color: error ? const Color(0xffa83027) : const Color(0xff526b39),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    ),
  );
}

class RecipeArt extends StatelessWidget {
  const RecipeArt({super.key, required this.category, this.large = false});
  final String category;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (category) {
      'Breakfast' => (const Color(0xffd79436), Icons.egg_alt_outlined),
      'Lunch' => (const Color(0xff718251), Icons.ramen_dining_outlined),
      'Dinner' => (recipeAccent, Icons.dinner_dining_outlined),
      _ => (const Color(0xff957080), Icons.cake_outlined),
    };
    return Container(
      width: large ? 116 : 54,
      height: large ? 116 : 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(large ? 30 : 15),
      ),
      child: Center(
        child: Container(
          width: large ? 87 : 42,
          height: large ? 87 : 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: .2)),
          ),
          child: Icon(icon, size: large ? 52 : 28, color: color),
        ),
      ),
    );
  }
}
