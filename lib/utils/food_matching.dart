/// Normalizes Vietnamese names for source lookup, never to classify nutrients.
String normalizeFoodName(String value) {
  var result = value.toLowerCase();
  const variants = [
    'àáảãạăằắẳẵặâầấẩẫậ',
    'èéẻẽẹêềếểễệ',
    'ìíỉĩị',
    'òóỏõọôồốổỗộơờớởỡợ',
    'ùúủũụưừứửữự',
    'ỳýỷỹỵ',
    'đ',
  ];
  const replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  for (var i = 0; i < variants.length; i++) {
    for (final character in variants[i].split('')) {
      result = result.replaceAll(character, replacements[i]);
    }
  }
  return result.replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
}

bool ingredientMatchesKeyword(String ingredient, String keyword) {
  final accentedFood = _canonicalFoodName(ingredient);
  final accentedTerm = _canonicalFoodName(keyword);
  final normalizedFood = normalizeFoodName(ingredient);
  final normalizedTerm = normalizeFoodName(keyword);
  // Preserve accented distinctions: "nước me" is not sesame ("mè").
  final hasAccents = accentedFood != normalizedFood;
  if (!hasAccents &&
      accentedTerm != normalizedTerm &&
      !normalizedTerm.contains(' ')) {
    return false;
  }
  final food = hasAccents ? accentedFood : normalizedFood;
  final term = hasAccents ? accentedTerm : normalizedTerm;
  if (term.isEmpty) return false;
  // "Đậu bắp" isn't a legume; broad aliases must not overrule specific names.
  if (normalizedTerm == 'dau' && normalizedFood != 'dau') {
    return false;
  }
  return ' $food '.contains(' $term ');
}

String _canonicalFoodName(String value) => value
    .toLowerCase()
    .replaceAll(
      RegExp(
        r'[^a-z0-9àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
      ),
      ' ',
    )
    .trim();
