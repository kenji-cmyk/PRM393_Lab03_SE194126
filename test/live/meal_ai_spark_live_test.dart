// Opt in explicitly; the normal test suite never reads a token or calls Gemini.
// PowerShell:
// $env:VETALIFE_RUN_LIVE_AI='1'
// $env:VETALIFE_LIVE_APP_CHECK_FILE='<ignored local App Check JWT file>'
// flutter.bat test --no-pub test/live/meal_ai_spark_live_test.dart
// Optionally set VETALIFE_RUN_LIVE_OCR='1' for one extra synthetic-image call.
// The token file is plain JWT text or JSON {"token":"<App Check JWT>"}.
// No Gemini API secret is accepted. Use tool/run_meal_ai_live_check.cjs to manage
// temporary token registration/revocation automatically.
// Optional diagnostics: VETALIFE_LIVE_DIAGNOSTIC_FILE=tmp/<name>.json writes
// sanitized error status/message only. VETALIFE_LIVE_REQUEST_FILE=tmp/<name>.json
// exports the synthetic serialized analysis request OFFLINE, without headers.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/firebase_options.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/ai_logic_meal_intelligence.dart';
import 'package:vetalife/services/meal_ai_grounding.dart';
import 'package:vetalife/services/meal_intelligence.dart';

const _model = 'gemini-3.6-flash';
const _syntheticUid = 'live-test-synthetic-owner';
const _syntheticName = 'SYNTHETIC TEST PROFILE';
const _syntheticMealId = 'live-test-synthetic-meal';

Future<String> _corpus() =>
    File('assets/content/meal-knowledge.json').readAsString();

MealDraft _draft() => MealDraft(
  id: _syntheticMealId,
  name: 'Cơm gạo lứt, đậu hũ và bông cải',
  mealType: MealType.lunch,
  eatenAt: DateTime(2026, 11, 4, 12),
  ingredients: const [
    MealIngredient(name: 'Gạo lứt', amount: '1 bát', preparation: 'nấu'),
    MealIngredient(name: 'Đậu hũ', amount: '100 g', preparation: 'hấp'),
    MealIngredient(name: 'Bông cải xanh', amount: '100 g', preparation: 'hấp'),
  ],
  notes: 'Dữ liệu giả phục vụ kiểm thử; thành phần đã xác nhận.',
);

UserProfile _profile() => UserProfile(
  displayName: _syntheticName,
  birthDate: DateTime(2000, 1, 1),
  weightKg: 60,
  heightCm: 165,
  goal: HabitGoal.addVegetables,
);

Map<String, Object?> _requestBody(MealAiRequest request) => {
  'systemInstruction': Content.system(request.systemInstruction).toJson(),
  'contents': request.contents.map((item) => item.toJson()).toList(),
  'generationConfig': GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: request.responseSchema,
    maxOutputTokens: 4096,
    temperature: 0.2,
  ).toJson(),
};

void main() {
  final enabled = Platform.environment['VETALIFE_RUN_LIVE_AI'] == '1';
  final ocrEnabled =
      enabled && Platform.environment['VETALIFE_RUN_LIVE_OCR'] == '1';
  final transport = _LiveTransport(maxCalls: ocrEnabled ? 2 : 1);
  tearDownAll(transport.close);

  AiLogicMealIntelligence service() => AiLogicMealIntelligence(
    generator: transport.generate,
    currentUserId: () => _syntheticUid,
    loadKnowledge: _corpus,
    now: () => DateTime(2026, 11, 4, 12),
    timeout: const Duration(seconds: 55),
    modelName: _model,
  );

  test('OFFLINE serializes the real grounded schema and optionally exports request', () async {
    MealAiRequest? captured;
    final offline = AiLogicMealIntelligence(
      currentUserId: () => _syntheticUid,
      loadKnowledge: _corpus,
      now: () => DateTime(2026, 11, 4),
      generator: (request) async {
        captured = request;
        return null;
      },
    );
    await expectLater(
      offline.analyze(_draft(), _profile()),
      throwsA(isA<MealServiceException>()),
    );
    final request = captured!;
    final schema = request.responseSchema.toJson();
    final properties = schema['properties']! as Map;
    final ids = (properties['sourceIds'] as Map)['items'] as Map;
    final connection = (properties['healthConnections'] as Map)['items'] as Map;
    final topic = (connection['properties'] as Map)['topic'] as Map;
    expect(ids['type'], 'STRING');
    expect(ids['format'], 'enum');
    expect((ids['enum'] as List).isNotEmpty, isTrue);
    expect(topic['type'], 'STRING');
    expect(topic['format'], 'enum');
    expect((topic['enum'] as List).isNotEmpty, isTrue);
    expect(
      schema['required'],
      containsAll(['sourceIds', 'healthConnections', 'summary']),
    );
    final body = _requestBody(request);
    final serialized = jsonEncode(body);
    expect(serialized.contains('x-firebase-appcheck'), isFalse);
    expect(serialized.contains('apiKey'), isFalse);
    expect(serialized.contains(_syntheticName), isFalse);
    final path = Platform.environment['VETALIFE_LIVE_REQUEST_FILE'];
    if (path != null && path.isNotEmpty) {
      await _writeIgnoredJson(path, body);
    }
  });

  test(
    'OFFLINE diagnostic redacts credentials and bounds provider message',
    () {
      final fakeKey = 'AIza${'A' * 35}';
      final fakeJwt = '${'a' * 20}.${'b' * 20}.${'c' * 20}';
      const fakeUuid = '12345678-abcd-1234-abcd-123456789abc';
      final result = _errorDiagnostic(
        500,
        utf8.encode(
          jsonEncode({
            'error': {
              'status': 'INTERNAL',
              'message': '$fakeKey $fakeJwt $fakeUuid ${'x' * 1200}',
              'details': ['This entire field must be omitted.'],
            },
          }),
        ),
        fakeJwt,
      );
      expect(result.keys.toSet(), {'httpStatus', 'status', 'message'});
      expect(result['status'], 'INTERNAL');
      final serialized = jsonEncode(result);
      expect(serialized.contains(fakeKey), isFalse);
      expect(serialized.contains(fakeJwt), isFalse);
      expect(serialized.contains(fakeUuid), isFalse);
      expect(serialized.contains('details'), isFalse);
      expect((result['message']! as String).length < 1000, isTrue);
      expect(
        _errorDiagnostic(
          500,
          utf8.encode('<html>private raw</html>'),
          '',
        )['message'],
        'Provider returned no readable error message.',
      );
    },
  );

  test(
    'LIVE Spark meal analysis validates real Gemini output against book corpus',
    () async {
      final draft = _draft();
      final profile = _profile();
      final selected = await MealAiGrounding(loadKnowledge: _corpus)
          .select(draft);
      final before = transport.calls;
      final result = await service().analyze(draft, profile);

      expect(transport.calls - before, 1);
      expect(result.mode, 'gemini');
      expect(result.title.isNotEmpty && result.summary.isNotEmpty, isTrue);
      expect(result.improvements.isNotEmpty, isTrue);
      expect(result.profileNote.isNotEmpty, isTrue);
      expect(result.references.isNotEmpty, isTrue);
      final selectedById = {
        for (final source in selected) source.reference.id: source,
      };
      final citedIds = result.references.map((item) => item.id).toSet();
      for (final reference in result.references) {
        final source = selectedById[reference.id];
        expect(
          source != null,
          isTrue,
          reason: 'Citation must be retrieved locally.',
        );
        expect(reference.toJson(), source!.reference.toJson());
      }
      for (final connection in result.healthConnections) {
        expect(connection.referenceIds.isNotEmpty, isTrue);
        for (final id in connection.referenceIds) {
          expect(citedIds.contains(id), isTrue);
          expect(
            selectedById[id]!.healthTopics.contains(connection.topic),
            isTrue,
          );
        }
      }
      expect(result.limitations.length >= 3, isTrue);
      // Deliberately report counts/verified page numbers, never raw model text.
      // ignore: avoid_print
      print(
        'LIVE analysis passed: model=$_model, citations=${result.references.length}, '
        'pages=${result.references.map((item) => item.printedPage).join(",")}, '
        'healthConnections=${result.healthConnections.length}.',
      );
    },
    skip: enabled ? false : 'Set VETALIFE_RUN_LIVE_AI=1 explicitly.',
    timeout: const Timeout(Duration(seconds: 70)),
  );

  test(
    'LIVE synthetic PNG tests image transport and OCR separation only',
    () async {
      final before = transport.calls;
      final result = await service().recognize(
        MealPhoto(
          bytes: await File('test/fixtures/meal_ocr_synthetic.png')
              .readAsBytes(),
          mimeType: 'image/png',
          fileName: 'synthetic-ocr.png',
        ),
      );
      expect(transport.calls - before, 1);
      final compact = result.ocrText
          .replaceAll(RegExp(r'\s+'), '')
          .toUpperCase();
      expect(
        compact.contains('SAMPLE') && compact.contains('31415'),
        isTrue,
        reason: 'Synthetic text should remain in the OCR field.',
      );
      expect(
        result.ingredients.isEmpty,
        isTrue,
        reason: 'A text-only card supplies no visible meal ingredients.',
      );
      expect(result.warnings.isNotEmpty, isTrue);
      // ignore: avoid_print
      print(
        'LIVE OCR passed: synthetic PNG, OCR separated, no food accuracy claim.',
      );
    },
    skip: ocrEnabled
        ? false
        : 'Set both VETALIFE_RUN_LIVE_AI=1 and VETALIFE_RUN_LIVE_OCR=1.',
    timeout: const Timeout(Duration(seconds: 70)),
  );
}

/// Uses the installed Firebase AI SDK's public serializers but real HTTP, so a
/// Flutter unit-test VM needs no platform Firebase/App Check plugin channels.
/// This boundary does not prove native/web App Check attestation or camera UI.
class _LiveTransport {
  _LiveTransport({required this.maxCalls});

  final int maxCalls;
  int calls = 0;
  bool _stopped = false;
  HttpClient? _client;

  void close() => _client?.close(force: true);

  Future<String?> generate(MealAiRequest request) async {
    if (_stopped || calls >= maxCalls) {
      throw const MealServiceException(
        'LIVE call budget exhausted; no retries.',
      );
    }
    expect(request.modelName, _model);
    expect(DefaultFirebaseOptions.web.projectId, 'vetalife-24f03');
    expect(request.prompt.contains(_syntheticUid), isFalse);
    expect(request.prompt.contains(_syntheticName), isFalse);
    expect(request.prompt.contains(_syntheticMealId), isFalse);
    expect(request.prompt.contains('2000-01-01'), isFalse);
    if (request.photo == null) {
      final prompt = jsonDecode(request.prompt) as Map<String, dynamic>;
      expect((prompt['profileMetadata'] as Map).keys.toSet(), {
        'age',
        'weightKg',
        'heightCm',
        'goal',
      });
      expect(prompt['profileMetadata'], {
        'age': 26,
        'weightKg': 60.0,
        'heightCm': 165.0,
        'goal': 'addVegetables',
      });
    } else {
      final image = request.contents.single.parts
          .whereType<InlineDataPart>()
          .single;
      expect(image.mimeType, 'image/png');
      expect(image.bytes.length > 100, isTrue);
    }
    final token = await _readToken();
    calls++;
    try {
      final client = _client ??= HttpClient()
        ..connectionTimeout = const Duration(seconds: 12);
      final uri = Uri.https(
        'firebasevertexai.googleapis.com',
        '/v1beta/projects/vetalife-24f03/models/$_model:generateContent',
      );
      final outgoing = await client.postUrl(uri);
      outgoing.followRedirects = false;
      outgoing.headers
        ..set('content-type', 'application/json')
        ..set('x-goog-api-key', DefaultFirebaseOptions.web.apiKey)
        ..set('x-firebase-appcheck', token);
      outgoing.add(utf8.encode(jsonEncode(_requestBody(request))));
      final incoming = await outgoing.close();
      if (incoming.statusCode != 200) {
        _stopped = true;
        final diagnosticPath =
            Platform.environment['VETALIFE_LIVE_DIAGNOSTIC_FILE'];
        if (diagnosticPath != null && diagnosticPath.isNotEmpty) {
          final errorBytes = <int>[];
          await for (final chunk in incoming) {
            errorBytes.addAll(chunk.take(64 * 1024 - errorBytes.length));
            if (errorBytes.length >= 64 * 1024) break;
          }
          await _writeIgnoredJson(
            diagnosticPath,
            _errorDiagnostic(incoming.statusCode, errorBytes, token),
          );
        }
        // Only an opt-in sanitized error summary is retained; no raw body/retry.
        throw MealServiceException(
          'LIVE AI Logic HTTP ${incoming.statusCode}; stopped without retry. '
          'Check App Check/provider setup or wait for quota reset.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in incoming) {
        bytes.addAll(chunk);
        if (bytes.length > 256 * 1024) {
          throw const MealServiceException(
            'LIVE response exceeded safety bound.',
          );
        }
      }
      final response = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const MealServiceException('LIVE Gemini returned no candidate.');
      }
      final first = candidates.first as Map<String, dynamic>;
      if (first['finishReason'] != 'STOP') {
        throw const MealServiceException(
          'LIVE Gemini did not finish normally.',
        );
      }
      final content = first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final text = parts
          .whereType<Map<String, dynamic>>()
          .where((part) => part['thought'] != true && part['text'] is String)
          .map((part) => part['text'] as String)
          .join();
      if (text.isEmpty) {
        throw const MealServiceException('LIVE Gemini returned no JSON text.');
      }
      return text;
    } on MealServiceException {
      _stopped = true;
      rethrow;
    } catch (_) {
      _stopped = true;
      throw const MealServiceException(
        'LIVE HTTP or response decoding failed; no raw provider data logged.',
      );
    }
  }

  Future<String> _readToken() async {
    final path = Platform.environment['VETALIFE_LIVE_APP_CHECK_FILE'];
    if (path == null || path.trim().isEmpty) {
      throw const MealServiceException(
        'Set VETALIFE_LIVE_APP_CHECK_FILE locally.',
      );
    }
    try {
      var token = (await File(path).readAsString()).trim();
      if (token.startsWith('{')) {
        final json = jsonDecode(token) as Map<String, dynamic>;
        token = json['token'] as String;
      }
      if (!RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$')
          .hasMatch(token)) {
        throw const FormatException('Invalid App Check JWT');
      }
      return token;
    } catch (_) {
      throw const MealServiceException(
        'Cannot read local App Check JWT; contents intentionally omitted.',
      );
    }
  }
}

Map<String, Object> _errorDiagnostic(
  int httpStatus,
  List<int> bytes,
  String token,
) {
  var status = 'UNKNOWN';
  var message = 'Provider returned no readable error message.';
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map && decoded['error'] is Map) {
      final error = decoded['error'] as Map;
      if (error['status'] case final String value
          when RegExp(r'^[A-Z_]{1,64}$').hasMatch(value)) {
        status = value;
      }
      if (error['message'] case final String value) {
        message = value;
      }
    }
  } catch (_) {
    // Malformed/overlong error bodies must never be included in diagnostics.
  }
  if (token.isNotEmpty) message = message.replaceAll(token, '[REDACTED]');
  message = message
      .replaceAll(RegExp(r'AIza[A-Za-z0-9_-]{20,}'), '[REDACTED_API_KEY]')
      .replaceAll(
        RegExp(
          r'\b[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\b',
        ),
        '[REDACTED_JWT]',
      )
      .replaceAll(
        RegExp(
          r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
          caseSensitive: false,
        ),
        '[REDACTED_UUID]',
      )
      .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
  if (message.length > 999) message = '${message.substring(0, 996)}...';
  return {'httpStatus': httpStatus, 'status': status, 'message': message};
}

Future<void> _writeIgnoredJson(String path, Map<String, Object?> data) async {
  // /tmp/ is ignored in this repository. Refuse accidental source-tree exports.
  final target = File(path).absolute.uri.normalizePath();
  final temp = Directory('tmp').absolute.uri.normalizePath();
  final root = temp.path.endsWith('/') ? temp.path : '${temp.path}/';
  if (!target.path.toLowerCase().startsWith(root.toLowerCase()) ||
      !target.path.toLowerCase().endsWith('.json')) {
    throw const MealServiceException(
      'LIVE diagnostics must target ignored tmp/*.json.',
    );
  }
  try {
    final file = File.fromUri(target);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  } catch (_) {
    throw const MealServiceException(
      'Cannot write ignored LIVE diagnostic file.',
    );
  }
}
