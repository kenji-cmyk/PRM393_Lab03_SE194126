import 'dart:typed_data';

enum MealType {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  dinner('Bữa tối'),
  snack('Bữa phụ');

  const MealType(this.label);
  final String label;
}

class MealIngredient {
  const MealIngredient({
    required this.name,
    this.amount = '',
    this.preparation = '',
  });

  final String name;
  final String amount;
  final String preparation;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'amount': amount.trim(),
    'preparation': preparation.trim(),
  };

  factory MealIngredient.fromJson(Map<String, dynamic> json) => MealIngredient(
    name: _text(json, 'name', max: 120),
    amount: _text(json, 'amount', max: 100, allowEmpty: true),
    preparation: _text(json, 'preparation', max: 120, allowEmpty: true),
  );
}

class MealPhoto {
  MealPhoto({
    required Uint8List bytes,
    required this.mimeType,
    required this.fileName,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}

class MealDraft {
  MealDraft({
    required this.id,
    required this.name,
    required this.mealType,
    required this.eatenAt,
    required List<MealIngredient> ingredients,
    this.notes = '',
  }) : ingredients = List.unmodifiable(ingredients);

  final String id;
  final String name;
  final MealType mealType;
  final DateTime eatenAt;
  final List<MealIngredient> ingredients;
  final String notes;

  MealDraft copyWith({
    String? name,
    MealType? mealType,
    DateTime? eatenAt,
    List<MealIngredient>? ingredients,
    String? notes,
  }) => MealDraft(
    id: id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    eatenAt: eatenAt ?? this.eatenAt,
    ingredients: ingredients ?? this.ingredients,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.trim(),
    'mealType': mealType.name,
    'eatenAt': eatenAt.toUtc().toIso8601String(),
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'notes': notes.trim(),
  };

  factory MealDraft.fromJson(Map<String, dynamic> json) {
    final type = _text(json, 'mealType');
    final eatenAt = DateTime.tryParse(_text(json, 'eatenAt'));
    final types = MealType.values.where((value) => value.name == type);
    if (eatenAt == null || types.isEmpty) {
      throw const FormatException('Invalid meal time/type');
    }
    return MealDraft(
      id: _text(json, 'id', max: 100),
      name: _text(json, 'name', max: 160),
      mealType: types.single,
      eatenAt: eatenAt.toLocal(),
      ingredients: _objects(
        json,
        'ingredients',
        max: 30,
      ).map(MealIngredient.fromJson).toList(),
      notes: _text(json, 'notes', max: 1000, allowEmpty: true),
    );
  }
}

class MealRecognition {
  MealRecognition({
    required this.mealName,
    required List<MealIngredient> ingredients,
    required this.ocrText,
    required List<String> warnings,
  }) : ingredients = List.unmodifiable(ingredients),
       warnings = List.unmodifiable(warnings);

  final String mealName;
  final List<MealIngredient> ingredients;
  final String ocrText;
  final List<String> warnings;

  factory MealRecognition.fromJson(Map<String, dynamic> json) =>
      MealRecognition(
        mealName: _text(json, 'mealName', max: 160, allowEmpty: true),
        ingredients: _objects(
          json,
          'ingredients',
          max: 30,
        ).map(MealIngredient.fromJson).toList(),
        ocrText: _text(json, 'ocrText', max: 4000, allowEmpty: true),
        warnings: _texts(json, 'warnings'),
      );
}

class BookReference {
  const BookReference({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.printedPage,
    required this.pdfPage,
    required this.summary,
  });

  final String id;
  final String chapterId;
  final String title;
  final int printedPage;
  final int pdfPage;
  final String summary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'title': title,
    'printedPage': printedPage,
    'pdfPage': pdfPage,
    'summary': summary,
  };

  factory BookReference.fromJson(Map<String, dynamic> json) {
    final page = json['printedPage'];
    final pdfPage = json['pdfPage'];
    if (page is! int || pdfPage is! int || page <= 0 || pdfPage != page + 2) {
      throw const FormatException('Invalid book page reference');
    }
    return BookReference(
      id: _text(json, 'id', max: 100),
      chapterId: _text(json, 'chapterId', max: 100),
      title: _text(json, 'title', max: 300),
      printedPage: page,
      pdfPage: pdfPage,
      summary: _text(json, 'summary', max: 2000),
    );
  }
}

class HealthConnection {
  HealthConnection({
    required this.topic,
    required this.explanation,
    required List<String> referenceIds,
  }) : referenceIds = List.unmodifiable(referenceIds);

  final String topic;
  final String explanation;
  final List<String> referenceIds;

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'explanation': explanation,
    'referenceIds': referenceIds,
  };

  factory HealthConnection.fromJson(Map<String, dynamic> json) =>
      HealthConnection(
        topic: _text(json, 'topic', max: 200),
        explanation: _text(json, 'explanation', max: 2000),
        referenceIds: _texts(json, 'referenceIds', max: 12),
      );
}

class MealAnalysis {
  MealAnalysis({
    required this.title,
    required this.summary,
    required List<String> highlights,
    required List<String> improvements,
    required this.profileNote,
    required List<String> limitations,
    required List<BookReference> references,
    required List<HealthConnection> healthConnections,
    required this.mode,
  }) : highlights = List.unmodifiable(highlights),
       improvements = List.unmodifiable(improvements),
       limitations = List.unmodifiable(limitations),
       references = List.unmodifiable(references),
       healthConnections = List.unmodifiable(healthConnections);

  final String title;
  final String summary;
  final List<String> highlights;
  final List<String> improvements;
  final String profileNote;
  final List<String> limitations;
  final List<BookReference> references;
  final List<HealthConnection> healthConnections;
  final String mode;

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'highlights': highlights,
    'improvements': improvements,
    'profileNote': profileNote,
    'limitations': limitations,
    'references': references.map((item) => item.toJson()).toList(),
    'healthConnections': healthConnections
        .map((item) => item.toJson())
        .toList(),
    'mode': mode,
  };

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    final mode = _text(json, 'mode');
    if (mode != 'gemini' && mode != 'localBook') {
      throw const FormatException('Invalid analysis mode');
    }
    final references = _objects(
      json,
      'references',
      max: 12,
    ).map(BookReference.fromJson).toList();
    final connections = _objects(
      json,
      'healthConnections',
      max: 8,
    ).map(HealthConnection.fromJson).toList();
    final ids = references.map((item) => item.id).toSet();
    if (ids.length != references.length ||
        connections.any(
          (item) =>
              item.referenceIds.isEmpty ||
              item.referenceIds.any((id) => !ids.contains(id)),
        )) {
      throw const FormatException('Unverified analysis references');
    }
    return MealAnalysis(
      title: _text(json, 'title', max: 300),
      summary: _text(json, 'summary', max: 3000),
      highlights: _texts(json, 'highlights'),
      improvements: _texts(json, 'improvements'),
      profileNote: _text(json, 'profileNote', max: 3000),
      limitations: _texts(json, 'limitations'),
      references: references,
      healthConnections: connections,
      mode: mode,
    );
  }
}

class MealRecord {
  const MealRecord({
    required this.id,
    required this.draft,
    required this.analysis,
    required this.savedAt,
  });

  final String id;
  final MealDraft draft;
  final MealAnalysis analysis;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'draft': draft.toJson(),
    'analysis': analysis.toJson(),
    'savedAt': savedAt.toUtc().toIso8601String(),
  };

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    final id = _text(json, 'id', max: 100);
    final draft = MealDraft.fromJson(_object(json['draft']));
    final savedAt = DateTime.tryParse(_text(json, 'savedAt'));
    if (draft.id != id || savedAt == null) {
      throw const FormatException('Invalid saved meal');
    }
    return MealRecord(
      id: id,
      draft: draft,
      analysis: MealAnalysis.fromJson(_object(json['analysis'])),
      savedAt: savedAt,
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) throw const FormatException('Invalid meal object');
  return Map<String, dynamic>.from(value);
}

String _text(
  Map<String, dynamic> json,
  String key, {
  int max = 500,
  bool allowEmpty = false,
}) {
  final value = json[key];
  if (value is! String ||
      value.length > max ||
      (!allowEmpty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value.trim();
}

List<Map<String, dynamic>> _objects(
  Map<String, dynamic> json,
  String key, {
  int max = 20,
}) {
  final value = json[key];
  if (value is! List || value.length > max) {
    throw FormatException('Invalid $key');
  }
  return value.map(_object).toList();
}

List<String> _texts(Map<String, dynamic> json, String key, {int max = 12}) {
  final value = json[key];
  if (value is! List ||
      value.length > max ||
      value.any(
        (item) => item is! String || item.trim().isEmpty || item.length > 3000,
      )) {
    throw FormatException('Invalid $key');
  }
  return value.cast<String>();
}
