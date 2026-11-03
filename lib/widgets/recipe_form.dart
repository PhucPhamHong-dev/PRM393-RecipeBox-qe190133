import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../validators.dart';

class RecipeForm extends StatefulWidget {
  const RecipeForm({
    super.key,
    this.initialRecipe,
    required this.onSubmit,
    this.onSuccess,
    this.onCancel,
  });
  final Recipe? initialRecipe;
  final Future<void> Function(RecipeDraft) onSubmit;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cookTime;
  late final TextEditingController _servings;
  late final TextEditingController _notes;
  String? _category;
  String? _difficulty;
  String? _error;
  bool _submitted = false;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final r = widget.initialRecipe;
    _name = TextEditingController(text: r?.name ?? '');
    _cookTime = TextEditingController(text: r?.cookTime.toString() ?? '');
    _servings = TextEditingController(text: r?.servings?.toString() ?? '');
    _notes = TextEditingController(text: r?.notes ?? '');
    _category = r?.category;
    _difficulty = r?.difficulty;
  }

  @override
  void dispose() {
    for (final c in [_name, _cookTime, _servings, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        RecipeDraft(
          name: _name.text,
          category: _category!,
          difficulty: _difficulty!,
          cookTime: int.parse(_cookTime.text.trim()),
          servings: _servings.text.trim().isEmpty
              ? null
              : int.parse(_servings.text.trim()),
          notes: _notes.text,
        ),
      );
      if (!mounted) return;
      if (widget.initialRecipe == null) {
        _form.currentState!.reset();
        for (final c in [_name, _cookTime, _servings, _notes]) {
          c.clear();
        }
        setState(() {
          _category = null;
          _difficulty = null;
          _submitted = false;
        });
      }
      widget.onSuccess?.call();
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save recipe. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _dropdown(
    String name,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    String? Function(String?) validator,
  ) {
    final mode = widget.initialRecipe == null ? 'add' : 'edit';
    return DropdownButtonFormField<String>(
      key: ValueKey('recipe_${name.toLowerCase()}_$mode'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: name),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('Choose ${name.toLowerCase()}'),
        ),
        ...items.map((v) => DropdownMenuItem(value: v, child: Text(v))),
      ],
      validator: validator,
      onChanged: _busy
          ? null
          : (v) {
              setState(() => onChanged(v));
              _changed();
            },
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    autovalidateMode: _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('recipe_name'),
          controller: _name,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.restaurant_menu_outlined),
          ),
          validator: Validators.name,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 16),
        _dropdown(
          'Category',
          _category,
          recipeCategories,
          (v) => _category = v,
          Validators.category,
        ),
        const SizedBox(height: 16),
        _dropdown(
          'Difficulty',
          _difficulty,
          recipeDifficulties,
          (v) => _difficulty = v,
          Validators.difficulty,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('recipe_cook_time'),
          controller: _cookTime,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Cook time (minutes)',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          validator: Validators.cookTime,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('recipe_servings'),
          controller: _servings,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Servings (optional)',
            prefixIcon: Icon(Icons.people_outline),
          ),
          validator: Validators.servings,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('recipe_notes'),
          controller: _notes,
          enabled: !_busy,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            alignLabelWithHint: true,
          ),
          validator: Validators.notes,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('recipe_submit'),
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.initialRecipe == null
                      ? Icons.add_rounded
                      : Icons.check_rounded,
                ),
          label: Text(widget.initialRecipe == null ? 'Add Recipe' : 'Save'),
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            key: const ValueKey('recipe_server_error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );
}
