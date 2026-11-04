import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';
import 'meal_intelligence.dart';

enum MealPhotoSource { camera, gallery }

abstract interface class MealPhotoPicker {
  Future<MealPhoto?> pick(MealPhotoSource source);
}

/// Camera/gallery images are held only in memory and never written to a journal.
class DeviceMealPhotoPicker implements MealPhotoPicker {
  DeviceMealPhotoPicker({
    ImagePicker? picker,
    SharedPreferencesAsync? preferences,
    this.sessionOwner = 'preview',
  }) : _picker = picker ?? ImagePicker(),
       _preferences = preferences ?? SharedPreferencesAsync();
  final ImagePicker _picker;
  final SharedPreferencesAsync _preferences;
  final String sessionOwner;
  static const pendingOwnerKey = 'vetalife.meal.pending-photo-owner.v1';
  static const maxImageBytes = 4 * 1024 * 1024;

  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async {
    final nativeAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final marker = '$sessionOwner|${DateTime.now().microsecondsSinceEpoch}';
    try {
      if (nativeAndroid) await _preferences.setString(pendingOwnerKey, marker);
      final file = await _picker.pickImage(
        source: source == MealPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      return file == null ? null : await _read(file);
    } on PlatformException {
      throw const MealServiceException(
        'Chưa mở được camera hoặc thư viện. Kiểm tra quyền truy cập, thử lại hoặc nhập món ăn bằng tay.',
      );
    } finally {
      if (nativeAndroid &&
          await _preferences.getString(pendingOwnerKey) == marker) {
        await _preferences.remove(pendingOwnerKey);
      }
    }
  }

  /// Android can recreate the activity while its camera is open.
  Future<MealPhoto?> recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final marker = await _preferences.getString(pendingOwnerKey);
    final response = await _picker.retrieveLostData();
    if (marker != null &&
        await _preferences.getString(pendingOwnerKey) == marker) {
      await _preferences.remove(pendingOwnerKey);
    }
    // Native picker recovery is global to the app. Discard results from a
    // different account or a preview session that has already signed out.
    if (marker == null || !marker.startsWith('$sessionOwner|')) return null;
    if (response.isEmpty) return null;
    if (response.exception != null) {
      throw const MealServiceException(
        'Không khôi phục được ảnh. Bạn có thể chụp lại hoặc nhập món ăn.',
      );
    }
    final files = response.files;
    return files == null || files.isEmpty ? null : _read(files.first);
  }

  Future<void> discardPendingPhoto() async {
    final marker = await _preferences.getString(pendingOwnerKey);
    if (marker != null && marker.startsWith('$sessionOwner|')) {
      await _preferences.remove(pendingOwnerKey);
    }
  }

  Future<MealPhoto> _read(XFile file) async {
    if (await file.length() > maxImageBytes) {
      throw const MealServiceException(
        'Ảnh lớn hơn 4 MB. Hãy chụp lại hoặc chọn ảnh nhỏ hơn.',
      );
    }
    final bytes = await file.readAsBytes();
    final mime = imageMimeType(bytes);
    if (bytes.length > maxImageBytes || mime == null) {
      throw const MealServiceException(
        'Chọn ảnh JPEG, PNG hoặc WebP không quá 4 MB.',
      );
    }
    return MealPhoto(bytes: bytes, mimeType: mime, fileName: file.name);
  }
}

String? imageMimeType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length >= 8 &&
      List.generate(8, (i) => bytes[i] == png[i]).every((matches) => matches)) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
