import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipebox/models/recipe.dart';

void main() {
  final cases = <List<String>>[
    ['PHỞ BÒ', 'phở bò'],
    ['Éclair', 'éclair'],
    ['ĐẬU HŨ', 'đậu hũ'],
    ['Straẞe', 'straße'],
    ['ſoup', 'soup'],
    ['ΟΣ', 'οσ'],
    ['ος', 'οσ'],
    ['µ Soup', 'μ soup'],
    ['Μ Soup', 'μ soup'],
    ['Kake', 'kake'],
    ['Å', 'å'],
    ['İ', 'İ'],
    ['Bánh 🍰 中文', 'bánh 🍰 中文'],
    [r'A(B)[C].*+?^$|\E', r'a(b)[c].*+?^$|\e'],
    ['E\u0301CLAIR', 'e\u0301clair'],
  ];
  for (final pair in cases) {
    test('Simple Unicode casefold preserves literal name: ${pair.first}', () {
      expect(canonicalRecipeName(pair.first), pair.last);
      expect(
        canonicalRecipeId('alice', pair.first),
        'alice_${sha256.convert(utf8.encode(pair.last))}',
      );
      expect(
        canonicalRecipeId('alice', pair.first),
        canonicalRecipeId('alice', pair.last),
      );
    });
  }
  test('Canonical IDs keep owners and accent distinctions separate', () {
    expect(
      canonicalRecipeId('alice', 'Pho'),
      isNot(canonicalRecipeId('alice', 'Phở')),
    );
    expect(
      canonicalRecipeId('alice', 'PHỞ BÒ'),
      isNot(canonicalRecipeId('bob', 'PHỞ BÒ')),
    );
    expect(
      canonicalRecipeId('alice', 'İ'),
      isNot(canonicalRecipeId('alice', 'i')),
    );
    expect(
      canonicalRecipeId('alice', 'ß'),
      isNot(canonicalRecipeId('alice', 'ss')),
    );
  });
  test(
    'Outer spaces are ignored, literal slashes cannot enter document ID',
    () {
      expect(
        canonicalRecipeId('alice', '  PHỞ BÒ  '),
        canonicalRecipeId('alice', 'phở bò'),
      );
      expect(canonicalRecipeId('alice', r'A/B\C'), isNot(contains('/')));
    },
  );
  test('Casefold is idempotent for every regression sample', () {
    for (final pair in cases) {
      final key = canonicalRecipeName(pair.first);
      expect(canonicalRecipeName(key), key);
    }
  });
  test('Composed and decomposed spellings preserve their original Unicode sequences', () {
    expect(canonicalRecipeName('Éclair'), 'éclair');
    expect(canonicalRecipeName('E\u0301CLAIR'), 'e\u0301clair');
    expect(
      canonicalRecipeId('alice', 'Éclair'),
      isNot(canonicalRecipeId('alice', 'E\u0301clair')),
    );
  });
}
