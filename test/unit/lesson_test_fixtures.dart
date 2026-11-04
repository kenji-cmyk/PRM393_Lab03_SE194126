import 'dart:convert';
import 'dart:io';

import 'package:vetalife/models/lesson.dart';

Map<String, dynamic> catalogueFixture() =>
    jsonDecode(File('assets/content/lesson-catalog.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> contentFixture() => {
  'schemaVersion': 1,
  'lessons': [
    for (final id in knownLessonIds)
      {
        'lessonId': id,
        'summary': 'Synthetic unit-test content, not runtime book content.',
        'sections': [
          {
            'heading': 'Test heading',
            'paragraphs': ['Test paragraph.'],
          },
        ],
        'reflection': 'Test question?',
        'sourcePages': [
          {'printedPage': 37, 'pdfPage': 39},
        ],
      },
  ],
};

LessonCatalog lessonFixture() =>
    LessonCatalog.fromJson(catalogueFixture(), contentFixture());
