import 'models/recipe.dart';

class Validators {
  static String? email(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Email is required';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)
        ? null
        : 'Please enter a valid email address';
  }

  static String? password(String? value, {bool register = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    return register && value.length < 6
        ? 'Password must be at least 6 characters'
        : null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    return value != password ? 'Passwords do not match' : null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return value.runes.length > 80
        ? 'Name must be at most 80 characters'
        : null;
  }

  static String? category(String? value) =>
      recipeCategories.contains(value) ? null : 'Please choose a category';
  static String? difficulty(String? value) =>
      recipeDifficulties.contains(value) ? null : 'Please choose a difficulty';
  static bool _whole(String t, int min, int max) {
    final n = int.tryParse(t);
    return RegExp(r'^\d+$').hasMatch(t) && n != null && n >= min && n <= max;
  }

  static String? cookTime(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Cook time is required';
    return _whole(t, 1, 600)
        ? null
        : 'Cook time must be a whole number from 1 to 600';
  }

  static String? servings(String? value) {
    final t = value?.trim() ?? '';
    return t.isEmpty || _whole(t, 1, 20)
        ? null
        : 'Servings must be a whole number from 1 to 20';
  }

  static String? notes(String? value) => (value?.runes.length ?? 0) > 300
      ? 'Notes must be at most 300 characters'
      : null;
}
