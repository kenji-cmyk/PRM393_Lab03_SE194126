import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/services/report_service.dart';

typedef _FetchHandler =
    Future<ResponseBody> Function(
      RequestOptions options,
      List<int> bodyBytes,
      Future<void>? cancelFuture,
    );

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _FetchHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    return _handler(options, chunks, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const _uid = 'alice_test-123';
const _ownerPrefix = 'u_YWxpY2VfdGVzdC0xMjM/reports/';
const _validPublicId =
    '${_ownerPrefix}11111111-2222-4333-8444-555555555555.pdf';
final _fixedNow = DateTime.utc(2026, 11, 11, 2, 0, 0);
int get _nowEpoch => _fixedNow.millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _validSignature() => {
  'cloudName': 'demo-cloud',
  'apiKey': 'demo-api-key',
  'timestamp': _nowEpoch,
  'signature': '8c688598ab17697d10ef2888b031d2dfb5a59e93',
  'publicId': _validPublicId,
  'resourceType': 'raw',
  'deliveryType': 'authenticated',
  'uploadPreset': 'vetalife-reports-signed',
  'maxBytes': maxReportBytes,
};

String _validDownloadUrl({
  String host = 'api.cloudinary.com',
  String scheme = 'https',
  String path = '/v1_1/demo-cloud/raw/download',
  String publicId = _validPublicId,
  String type = 'authenticated',
  String format = 'pdf',
  int? expiresAt,
  String signature = '0ed56b9181b5b54e80a9c1ce03a222e02415b6b0',
}) => Uri(
  scheme: scheme,
  host: host,
  path: path,
  queryParameters: {
    'timestamp': _nowEpoch.toString(),
    'public_id': publicId,
    'format': format,
    'type': type,
    'attachment': 'true',
    'expires_at': (expiresAt ?? (_nowEpoch + 600)).toString(),
    'signature': signature,
    'api_key': 'demo-api-key',
  },
).toString();

void main() {
  test(
    'upload sends multipart fields matching signed params and returns cloudinary URI',
    () async {
      RequestOptions? capturedOptions;
      late String capturedBody;
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter((options, bytes, _) async {
          capturedOptions = options;
          capturedBody = utf8.decode(bytes, allowMalformed: true);
          return _jsonResponse(200, {
            'public_id': _validPublicId,
            'resource_type': 'raw',
            'type': 'authenticated',
          });
        });

      String? calledFunction;
      final service = PdfReportService(
        uid: _uid,
        currentUserId: () => _uid,
        dio: dio,
        now: () => _fixedNow,
        callCallable: (name, [data]) async {
          calledFunction = name;
          return _validSignature();
        },
      );

      final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7\nsynthetic'));
      final progressValues = <double>[];
      final uploaded = await service.upload(pdfBytes, progressValues.add);

      expect(calledFunction, 'createReportUploadSignature');
      expect(
        capturedOptions?.uri.toString(),
        'https://api.cloudinary.com/v1_1/demo-cloud/raw/upload',
      );
      expect(capturedOptions?.method, 'POST');
      expect(capturedBody, contains('name="api_key"\r\n\r\ndemo-api-key'));
      expect(
        capturedBody,
        contains('name="timestamp"\r\n\r\n${_nowEpoch.toString()}'),
      );
      expect(
        capturedBody,
        contains(
          'name="signature"\r\n\r\n8c688598ab17697d10ef2888b031d2dfb5a59e93',
        ),
      );
      expect(
        capturedBody,
        contains('name="public_id"\r\n\r\n$_validPublicId'),
      );
      expect(capturedBody, contains('name="type"\r\n\r\nauthenticated'));
      expect(
        capturedBody,
        contains('name="upload_preset"\r\n\r\nvetalife-reports-signed'),
      );
      expect(capturedBody, contains('name="overwrite"\r\n\r\nfalse'));
      expect(capturedBody, contains('filename="report.pdf"'));
      expect(uploaded.path, _validPublicId);
      expect(
        uploaded.storageUri,
        'cloudinary://authenticated/$_validPublicId',
      );
    },
  );

  test(
    'upload rejects empty and >10 MiB payloads before calling signer',
    () async {
      var callableHits = 0;
      final service = PdfReportService(
        uid: _uid,
        currentUserId: () => _uid,
        callCallable: (name, [data]) async {
          callableHits++;
          return _validSignature();
        },
      );

      await expectLater(service.upload(Uint8List(0), (_) {}), throwsStateError);
      await expectLater(
        service.upload(Uint8List(maxReportBytes + 1), (_) {}),
        throwsStateError,
      );
      expect(callableHits, 0);
    },
  );

  test(
    'upload rejects mismatched owner prefix, resource/delivery type or Cloudinary rejection',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          (options, bytes, _) async => _jsonResponse(200, {
            'public_id': 'wrong-folder/$_validPublicId',
            'resource_type': 'raw',
            'type': 'authenticated',
          }),
        );

      for (final badPatch in [
        {'resourceType': 'image'},
        {'deliveryType': 'upload'},
        {'publicId': 'u_b3RoZXI/reports/11111111-2222-4333-8444-555555555555.pdf'},
        {'maxBytes': 1024},
      ]) {
        final service = PdfReportService(
          uid: _uid,
          currentUserId: () => _uid,
          dio: dio,
          callCallable: (_, [_]) async => {..._validSignature(), ...badPatch},
        );
        await expectLater(
          service.upload(Uint8List.fromList([1, 2, 3]), (_) {}),
          throwsStateError,
        );
      }

      final rejectedByCloudinary = PdfReportService(
        uid: _uid,
        currentUserId: () => _uid,
        dio: dio,
        callCallable: (_, [_]) async => _validSignature(),
      );
      await expectLater(
        rejectedByCloudinary.upload(Uint8List.fromList([1, 2, 3]), (_) {}),
        throwsStateError,
      );
    },
  );

  test(
    'upload supports cancellation mid-flight and clears lock for retry',
    () async {
      final started = Completer<void>();
      var failNetwork = false;
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter((
          options,
          bytes,
          cancelFuture,
        ) async {
          if (failNetwork) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'offline',
            );
          }
          if (!started.isCompleted) started.complete();
          await cancelFuture;
          return _jsonResponse(200, {
            'public_id': _validPublicId,
            'resource_type': 'raw',
            'type': 'authenticated',
          });
        });

      final service = PdfReportService(
        uid: _uid,
        currentUserId: () => _uid,
        dio: dio,
        callCallable: (_, [_]) async => _validSignature(),
      );

      final uploadFuture = service.upload(
        Uint8List.fromList([37, 80, 68, 70]),
        (_) {},
      );
      await started.future;
      await service.cancel();
      await expectLater(uploadFuture, throwsA(isA<ReportCancelled>()));

      // Ensure retry after network failure also works cleanly without stuck token.
      failNetwork = true;
      await expectLater(
        service.upload(Uint8List.fromList([37, 80, 68, 70]), (_) {}),
        throwsA(isA<DioException>()),
      );
    },
  );

  test(
    'download validates signed URL contract, fetches PDF bytes, and blocks cross-user/tampered URLs',
    () async {
      final expectedPdf = Uint8List.fromList(utf8.encode('%PDF-1.7\nok'));
      var urlToReturn = _validDownloadUrl();
      RequestOptions? downloadRequest;

      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter((options, _, _) async {
          downloadRequest = options;
          return ResponseBody.fromBytes(expectedPdf, 200);
        });

      String? callableName;
      Map<String, Object?>? callableData;
      final service = PdfReportService(
        uid: _uid,
        currentUserId: () => _uid,
        dio: dio,
        now: () => _fixedNow,
        callCallable: (name, [data]) async {
          callableName = name;
          callableData = data;
          return {'url': urlToReturn, 'expiresAt': _nowEpoch + 600};
        },
      );

      final report = const UploadedReport(
        path: _validPublicId,
        storageUri: 'cloudinary://authenticated/$_validPublicId',
      );
      final downloaded = await service.download(report);
      expect(callableName, 'getReportDownloadUrl');
      expect(callableData, {'publicId': _validPublicId});
      expect(downloadRequest?.uri.toString(), urlToReturn);
      expect(downloaded, expectedPdf);

      // Cross-user report path is rejected locally before any callable call.
      callableName = null;
      await expectLater(
        service.download(
          const UploadedReport(
            path: 'u_b3RoZXI/reports/11111111-2222-4333-8444-555555555555.pdf',
            storageUri: 'cloudinary://authenticated/other',
          ),
        ),
        throwsStateError,
      );
      expect(callableName, isNull);

      // Expired, non-HTTPS, wrong host, wrong type, or tampered URLs are rejected.
      for (final badUrl in [
        _validDownloadUrl(scheme: 'http'),
        _validDownloadUrl(host: 'evil.example.com'),
        _validDownloadUrl(path: '/v1_1/demo-cloud/image/download'),
        _validDownloadUrl(type: 'upload'),
        _validDownloadUrl(format: 'txt'),
        _validDownloadUrl(expiresAt: _nowEpoch - 1),
        _validDownloadUrl(expiresAt: _nowEpoch + 31 * 60),
        _validDownloadUrl(signature: 'not-hex'),
      ]) {
        urlToReturn = badUrl;
        await expectLater(service.download(report), throwsStateError);
      }
    },
  );
}

