import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/lesson.dart';

class AssetLessonCatalog {
  AssetLessonCatalog({Future<String> Function(String path)? loadString})
    : _loadString = loadString ?? rootBundle.loadString;
  final Future<String> Function(String path) _loadString;

  Future<LessonCatalog> load() async {
    final json = await Future.wait([
      _loadString('assets/content/lesson-catalog.json'),
      _loadString('assets/content/lesson-content.json'),
    ]);
    final catalogue = jsonDecode(json[0]);
    final content = jsonDecode(json[1]);
    if (catalogue is! Map<String, dynamic> ||
        content is! Map<String, dynamic>) {
      throw const FormatException('Invalid lesson assets');
    }
    return LessonCatalog.fromJson(catalogue, content);
  }
}
