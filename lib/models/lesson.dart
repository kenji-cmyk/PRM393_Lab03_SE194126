/// Stable identities from the inspected book catalogue, shared with progress.
const knownLessonIds = <String>{
  'p1-ch01',
  'p1-ch02',
  'p1-ch03',
  'p1-ch04',
  'p1-ch05',
  'p1-ch06',
  'p1-ch07',
  'p1-ch08',
  'p1-ch09',
  'p1-ch10',
  'p1-ch11',
  'p1-ch12',
  'p1-ch13',
  'p1-ch14',
  'p1-ch15',
  'p2-introduction',
  'p2-daily-dozen',
  'p2-dd01',
  'p2-dd02',
  'p2-dd03',
  'p2-dd04',
  'p2-dd05',
  'p2-dd06',
  'p2-dd07',
  'p2-dd08',
  'p2-dd09',
  'p2-dd10',
  'p2-dd11',
  'p2-dd12',
  'p2-conclusion',
};

class LessonSourcePage {
  const LessonSourcePage({required this.printedPage, required this.pdfPage});
  final int printedPage;
  final int pdfPage;
  factory LessonSourcePage.fromJson(Map<String, dynamic> json) {
    final printed = json['printedPage'];
    final pdf = json['pdfPage'];
    if (printed is! int || printed < 1 || printed > 772 || pdf != printed + 2) {
      throw const FormatException('Invalid lesson source page');
    }
    return LessonSourcePage(printedPage: printed, pdfPage: pdf as int);
  }
}

class LessonSection {
  const LessonSection({required this.heading, required this.paragraphs});
  final String heading;
  final List<String> paragraphs;
  factory LessonSection.fromJson(Map<String, dynamic> json) => LessonSection(
    heading: _text(json, 'heading', max: 200),
    paragraphs: List.unmodifiable(
      _texts(json['paragraphs'], max: 12, length: 5000),
    ),
  );
}

class LessonBody {
  const LessonBody({
    required this.lessonId,
    required this.summary,
    required this.sections,
    required this.reflection,
    required this.sourcePages,
  });
  final String lessonId;
  final String summary;
  final List<LessonSection> sections;
  final String reflection;
  final List<LessonSourcePage> sourcePages;
  factory LessonBody.fromJson(Map<String, dynamic> json) {
    final id = _text(json, 'lessonId', max: 40);
    if (!knownLessonIds.contains(id)) {
      throw const FormatException('Unknown lesson');
    }
    return LessonBody(
      lessonId: id,
      summary: _text(json, 'summary', max: 3000),
      sections: List.unmodifiable(
        _objects(json['sections'], max: 12).map(LessonSection.fromJson),
      ),
      reflection: _text(json, 'reflection', max: 1500),
      sourcePages: List.unmodifiable(
        _objects(json['sourcePages'], max: 20).map(LessonSourcePage.fromJson),
      ),
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.partId,
    required this.sourceTitle,
    required this.displayTitle,
    required this.printedPage,
    required this.pdfPage,
    required this.kind,
    required this.body,
  });
  final String id;
  final String partId;
  final String sourceTitle;
  final String displayTitle;
  final int printedPage;
  final int pdfPage;
  final String kind;
  final LessonBody body;
  bool get isCore => kind == 'chapter' || kind == 'daily_dozen_category';
}

class LessonPart {
  const LessonPart({
    required this.id,
    required this.displayTitle,
    required this.units,
  });
  final String id;
  final String displayTitle;

  /// Source order with a parent overview immediately followed by its children.
  final List<Lesson> units;
}

class LessonCatalog {
  const LessonCatalog({
    required this.bookTitle,
    required this.authors,
    required this.parts,
  });
  final String bookTitle;
  final List<String> authors;
  final List<LessonPart> parts;
  List<Lesson> get lessons =>
      List.unmodifiable(parts.expand((part) => part.units));
  int get coreCount => lessons.where((lesson) => lesson.isCore).length;
  Lesson? lessonById(String id) {
    for (final part in parts) {
      for (final lesson in part.units) {
        if (lesson.id == id) return lesson;
      }
    }
    return null;
  }

  factory LessonCatalog.fromJson(
    Map<String, dynamic> catalogue,
    Map<String, dynamic> content,
  ) {
    if (catalogue['schemaVersion'] != 1 || content['schemaVersion'] != 1) {
      throw const FormatException('Unsupported lesson asset version');
    }
    final bodies = <String, LessonBody>{};
    for (final entry in _objects(content['lessons'], max: 30)) {
      final body = LessonBody.fromJson(entry);
      if (bodies.containsKey(body.lessonId)) {
        throw const FormatException('Duplicate lesson body');
      }
      bodies[body.lessonId] = body;
    }
    final ids = <String>{};
    final parts = <LessonPart>[];
    for (final part in _objects(catalogue['parts'], max: 2)) {
      final partId = _text(part, 'id', max: 20);
      if (!['part-1', 'part-2'].contains(partId) ||
          parts.any((item) => item.id == partId)) {
        throw const FormatException('Invalid lesson part');
      }
      final units = <Lesson>[];
      void addUnit(Map<String, dynamic> unit) {
        final id = _text(unit, 'id', max: 40);
        if (!knownLessonIds.contains(id) ||
            !ids.add(id) ||
            !id.startsWith(partId == 'part-1' ? 'p1-' : 'p2-')) {
          throw const FormatException('Invalid catalogue identity');
        }
        final body = bodies[id];
        if (body == null) throw const FormatException('Missing lesson body');
        final pages = LessonSourcePage.fromJson(unit);
        final kind = _text(unit, 'kind', max: 40);
        final expectedKind = id.startsWith('p1-')
            ? 'chapter'
            : id.startsWith('p2-dd')
            ? 'daily_dozen_category'
            : id == 'p2-conclusion'
            ? 'conclusion'
            : 'overview';
        if (kind != expectedKind) {
          throw const FormatException('Invalid lesson kind');
        }
        units.add(
          Lesson(
            id: id,
            partId: partId,
            sourceTitle: _text(unit, 'sourceTitle', max: 500),
            displayTitle: _text(unit, 'displayTitle', max: 300),
            printedPage: pages.printedPage,
            pdfPage: pages.pdfPage,
            kind: kind,
            body: body,
          ),
        );
        if (unit.containsKey('children')) {
          for (final child in _objects(unit['children'], max: 12)) {
            addUnit(child);
          }
        }
      }

      for (final unit in _objects(part['units'], max: 30)) {
        addUnit(unit);
      }
      parts.add(
        LessonPart(
          id: partId,
          displayTitle: _text(part, 'displayTitle', max: 80),
          units: List.unmodifiable(units),
        ),
      );
    }
    if (ids.length != 30 ||
        !ids.containsAll(knownLessonIds) ||
        bodies.length != ids.length ||
        parts.length != 2 ||
        parts.first.id != 'part-1') {
      throw const FormatException('Incomplete lesson catalogue');
    }
    final book = _object(catalogue['book']);
    return LessonCatalog(
      bookTitle: _text(book, 'title', max: 300),
      authors: List.unmodifiable(_texts(book['authors'], max: 5, length: 120)),
      parts: List.unmodifiable(parts),
    );
  }
}

class LessonReadProgress {
  const LessonReadProgress({required this.lessonId, required this.readAt});
  final String lessonId;
  final DateTime readAt;
  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'readAt': readAt.toUtc().toIso8601String(),
  };
  factory LessonReadProgress.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        !json.containsKey('lessonId') ||
        !json.containsKey('readAt') ||
        !knownLessonIds.contains(json['lessonId']) ||
        json['readAt'] is! String) {
      throw const FormatException('Invalid lesson progress');
    }
    final value = json['readAt'] as String;
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
      throw const FormatException('Invalid lesson read time');
    }
    return LessonReadProgress(
      lessonId: json['lessonId'] as String,
      readAt: parsed,
    );
  }
}

String _text(Map<String, dynamic> json, String key, {required int max}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty || value.length > max) {
    throw const FormatException('Invalid lesson text');
  }
  return value.trim();
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid lesson object');
  }
  return value;
}

List<Map<String, dynamic>> _objects(Object? value, {required int max}) {
  if (value is! List || value.isEmpty || value.length > max) {
    throw const FormatException('Invalid lesson list');
  }
  return value.map(_object).toList();
}

List<String> _texts(Object? value, {required int max, required int length}) {
  if (value is! List ||
      value.isEmpty ||
      value.length > max ||
      value.any(
        (item) =>
            item is! String || item.trim().isEmpty || item.length > length,
      )) {
    throw const FormatException('Invalid lesson text list');
  }
  return value.cast<String>().map((item) => item.trim()).toList();
}
