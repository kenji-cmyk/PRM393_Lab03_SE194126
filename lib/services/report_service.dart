import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/habit_goal.dart';
import '../models/lesson.dart';
import '../models/meal.dart';
import '../models/user_profile.dart';

const maxReportBytes = 10 * 1024 * 1024;

class ReportData {
  ReportData({
    required this.profile,
    required List<MealRecord> meals,
    required List<LessonReadProgress> progress,
    this.catalog,
  }) : meals = List.unmodifiable(meals),
       progress = List.unmodifiable(progress);
  final UserProfile profile;
  final List<MealRecord> meals;
  final List<LessonReadProgress> progress;
  final LessonCatalog? catalog;
}

class UploadedReport {
  const UploadedReport({required this.path, required this.storageUri});

  /// Storage path scoped to the authenticated Firebase user.
  final String path;

  /// A non-secret locator; opening the report requires owner authentication.
  final String storageUri;
}

abstract interface class ReportService {
  Future<Uint8List> generate(ReportData data);
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  );
  Future<Uint8List> download(UploadedReport report);
  Future<void> cancel();
  Future<void> open(Uint8List bytes);
}

class SavedReport {
  const SavedReport({
    required this.report,
    required this.createdAt,
    required this.sizeBytes,
  });

  final UploadedReport report;
  final DateTime createdAt;
  final int sizeBytes;
}

abstract interface class ReportArchive {
  Future<List<SavedReport>> listRecent();
}

class ReportStorageException implements Exception {
  const ReportStorageException(this.message);
  final String message;
}

class ReportCancelled implements Exception {
  const ReportCancelled();
}

typedef ReportCallable = Future<Map<String, dynamic>> Function(
  String name, [
  Map<String, Object?>? data,
]);

/// No Firebase instance is touched in preview mode.
class PdfReportService implements ReportService {
  PdfReportService({
    this.uid,
    this.currentUserId,
    this._functions,
    this._callCallable,
    Dio? dio,
    DateTime Function()? now,
    Future<ByteData> Function(String)? loadFont,
  }) : _now = now ?? DateTime.now,
       _loadFont = loadFont ?? rootBundle.load,
       _dio = dio ?? Dio();

  final String? uid;
  final String? Function()? currentUserId;
  final FirebaseFunctions? _functions;
  final ReportCallable? _callCallable;
  final Dio _dio;
  final DateTime Function() _now;
  final Future<ByteData> Function(String) _loadFont;
  CancelToken? _uploadToken;
  int _uploadGeneration = 0;

  void _requireOwner() {
    if (uid == null || uid!.isEmpty || currentUserId?.call() != uid) {
      throw StateError('Report session changed');
    }
  }

  @override
  Future<Uint8List> generate(ReportData data) async {
    final regular = await _loadFont('assets/fonts/Roboto-Regular.ttf');
    final bold = await _loadFont('assets/fonts/Roboto-Bold.ttf');
    final doc = pw.Document();
    final meals = [...data.meals]
      ..sort((a, b) => b.draft.eatenAt.compareTo(a.draft.eatenAt));
    final progress = {
      ...{for (final p in data.progress) p.lessonId: p},
    };
    final now = _now();
    String date(DateTime value) {
      final local = value.toLocal();
      return '${local.day}/${local.month}/${local.year}';
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(regular),
          bold: pw.Font.ttf(bold),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'VetaLife · ${context.pageNumber}/${context.pagesCount}',
          ),
        ),
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('VetaLife — Báo cáo cá nhân')),
          pw.Text('Ngày tạo: ${date(now)}'),
          pw.SizedBox(height: 12),
          pw.Text('Họ tên: ${data.profile.displayName}'),
          pw.Text('Mục tiêu: ${data.profile.goal.title}'),
          pw.Text(
            'Tuổi: ${data.profile.ageAt(now)} · Cân nặng: ${data.profile.weightKg} kg · Chiều cao: ${data.profile.heightCm} cm',
          ),
          pw.Header(
            level: 1,
            child: pw.Text('Nhật ký: ${meals.length} bữa ăn đã lưu'),
          ),
          if (meals.isEmpty) pw.Text('Chưa có bữa ăn đã lưu.'),
          for (final meal in meals) ...[
            pw.Text(
              '${date(meal.draft.eatenAt)} · ${meal.draft.mealType.label} · ${meal.draft.name}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final ingredient in meal.draft.ingredients)
              pw.Text(
                [
                  ingredient.name,
                  ingredient.amount,
                  ingredient.preparation,
                ].where((text) => text.isNotEmpty).join(' — '),
              ),
            pw.SizedBox(height: 8),
          ],
          pw.Header(
            level: 1,
            child: pw.Text('Học tập: ${progress.length} bài đã đánh dấu đọc'),
          ),
          if (progress.isEmpty) pw.Text('Chưa có bài đánh dấu đã đọc.'),
          for (final read in progress.values)
            pw.Text(
              '${date(read.readAt)} · ${data.catalog?.lessonById(read.lessonId)?.displayTitle ?? read.lessonId}',
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Báo cáo phản ánh dữ liệu đã lưu, không phải đánh giá sức khỏe hoặc chẩn đoán y tế.',
          ),
        ],
      ),
    );
    final bytes = await doc.save();
    if (bytes.length > maxReportBytes) throw StateError('Report too large');
    return bytes;
  }

  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    _requireOwner();
    if (bytes.isEmpty ||
        bytes.length > maxReportBytes ||
        _uploadToken != null) {
      throw StateError('Invalid report upload');
    }
    final generation = ++_uploadGeneration;
    final token = CancelToken();
    _uploadToken = token;
    try {
      final signature = await _callMap('createReportUploadSignature');
      _requireOwner();
      if (generation != _uploadGeneration || token.isCancelled) {
        throw const ReportCancelled();
      }

      final cloudName = _requiredString(signature, 'cloudName');
      final apiKey = _requiredString(signature, 'apiKey');
      final uploadSignature = _requiredString(signature, 'signature');
      final publicId = _requiredString(signature, 'publicId');
      final resourceType = _requiredString(signature, 'resourceType');
      final deliveryType = _requiredString(signature, 'deliveryType');
      final uploadPreset = _requiredString(signature, 'uploadPreset');
      final timestamp = signature['timestamp'];
      final maxBytes = signature['maxBytes'];
      if (resourceType != 'raw' ||
          deliveryType != 'authenticated' ||
          !_isOwnedPublicId(publicId) ||
          timestamp is! int ||
          maxBytes != maxReportBytes) {
        throw StateError('Invalid report upload signature');
      }

      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'report.pdf'),
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': uploadSignature,
        'public_id': publicId,
        'type': deliveryType,
        'upload_preset': uploadPreset,
        'overwrite': false,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
        data: form,
        cancelToken: token,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 90),
        ),
        onSendProgress: (sent, total) {
          if (generation == _uploadGeneration &&
              currentUserId?.call() == uid &&
              total > 0) {
            progress((sent / total).clamp(0, 1));
          }
        },
      );
      if (generation != _uploadGeneration) throw const ReportCancelled();
      _requireOwner();
      final body = response.data;
      if (response.statusCode != 200 ||
          body?['public_id'] != publicId ||
          body?['resource_type'] != 'raw' ||
          body?['type'] != 'authenticated') {
        throw StateError('Cloudinary rejected the report upload');
      }
      return UploadedReport(
        path: publicId,
        storageUri: 'cloudinary://authenticated/$publicId',
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || generation != _uploadGeneration) {
        throw const ReportCancelled();
      }
      rethrow;
    } finally {
      if (identical(_uploadToken, token)) _uploadToken = null;
    }
  }

  @override
  Future<Uint8List> download(UploadedReport report) async {
    _requireOwner();
    if (!_isOwnedPublicId(report.path)) {
      throw StateError('Invalid report owner');
    }

    final result = await _callMap('getReportDownloadUrl', {
      'publicId': report.path,
    });
    final url = Uri.tryParse(_requiredString(result, 'url'));
    final query = url?.queryParameters;
    final expiresAt = int.tryParse(query?['expires_at'] ?? '');
    final now = _now().millisecondsSinceEpoch ~/ 1000;
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'api.cloudinary.com' ||
        !RegExp(r'^/v1_1/[^/]+/raw/download$').hasMatch(url.path) ||
        query?['public_id'] != report.path ||
        query?['type'] != 'authenticated' ||
        query?['format'] != 'pdf' ||
        query?['api_key']?.isNotEmpty != true ||
        !RegExp(
          r'^[0-9a-f]{40,128}$',
          caseSensitive: false,
        ).hasMatch(query?['signature'] ?? '') ||
        expiresAt == null ||
        expiresAt <= now ||
        expiresAt > now + const Duration(minutes: 30).inSeconds) {
      throw StateError('Invalid private report URL');
    }
    final response = await _dio.get<List<int>>(
      url.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status == 200,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _requireOwner();
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty || bytes.length > maxReportBytes) {
      throw StateError('Report unavailable');
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> cancel() async {
    ++_uploadGeneration;
    _uploadToken?.cancel('User cancelled report upload');
  }

  Future<Map<String, dynamic>> _callMap(
    String name, [
    Map<String, Object?>? data,
  ]) async {
    if (_callCallable != null) {
      return _callCallable(name, data);
    }
    final result =
        await (_functions ??
                FirebaseFunctions.instanceFor(region: 'asia-southeast1'))
            .httpsCallable(
              name,
              options: HttpsCallableOptions(
                timeout: const Duration(seconds: 30),
              ),
            )
            .call<Object?>(data ?? const <String, Object?>{});
    final payload = result.data;
    if (payload is! Map) {
      throw StateError('Invalid report service response');
    }
    return Map<String, dynamic>.from(payload);
  }

  String _requiredString(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! String || result.isEmpty) {
      throw StateError('Invalid report service response');
    }
    return result;
  }

  bool _isOwnedPublicId(String publicId) {
    final expectedOwner =
        'u_${base64Url.encode(utf8.encode(uid!)).replaceAll('=', '')}';
    final parts = publicId.split('/');
    return parts.length == 3 &&
        parts[0] == expectedOwner &&
        parts[1] == 'reports' &&
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.pdf$',
          caseSensitive: false,
        ).hasMatch(parts[2]);
  }

  @override
  Future<void> open(Uint8List bytes) async {
    await Printing.layoutPdf(
      name: 'VetaLife-report.pdf',
      onLayout: (_) async => bytes,
    );
  }
}
