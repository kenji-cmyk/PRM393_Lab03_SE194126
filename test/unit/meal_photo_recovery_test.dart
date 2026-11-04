import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/services/meal_photo_picker.dart';

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NativePicker extends ImagePicker {
  int recoveries = 0;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    recoveries++;
    return LostDataResponse(
      type: RetrieveType.image,
      files: [
        XFile.fromData(
          Uint8List.fromList([0xff, 0xd8, 0xff]),
          name: 'recovered.jpg',
          mimeType: 'image/jpeg',
        ),
      ],
    );
  }
}

void main() {
  late _Preferences preferences;
  late _NativePicker nativePicker;

  DeviceMealPhotoPicker pickerFor(String owner) => DeviceMealPhotoPicker(
    picker: nativePicker,
    preferences: preferences,
    sessionOwner: owner,
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    preferences = _Preferences();
    nativePicker = _NativePicker();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'pending photo from another account is consumed and discarded',
    () async {
      preferences.values[DeviceMealPhotoPicker.pendingOwnerKey] =
          'cloud:owner-a|123';
      final photo = await pickerFor('cloud:owner-b').recoverLostPhoto();
      expect(photo, isNull);
      expect(nativePicker.recoveries, 1);
      expect(
        preferences.values.containsKey(DeviceMealPhotoPicker.pendingOwnerKey),
        isFalse,
      );
    },
  );

  test(
    'matching account may recover its photo once and clears the marker',
    () async {
      preferences.values[DeviceMealPhotoPicker.pendingOwnerKey] =
          'cloud:owner-a|123';
      final photo = await pickerFor('cloud:owner-a').recoverLostPhoto();
      expect(photo, isNotNull);
      expect(photo!.bytes, [0xff, 0xd8, 0xff]);
      expect(photo.mimeType, 'image/jpeg');
      expect(
        preferences.values.containsKey(DeviceMealPhotoPicker.pendingOwnerKey),
        isFalse,
      );
      expect(await pickerFor('cloud:owner-a').recoverLostPhoto(), isNull);
    },
  );

  test(
    'photo without a pending owner is never recovered after sign-out',
    () async {
      final photo = await pickerFor('preview').recoverLostPhoto();
      expect(photo, isNull);
      expect(nativePicker.recoveries, 1);
    },
  );

  test('preview photo cannot be exposed to a signed-in account', () async {
    preferences.values[DeviceMealPhotoPicker.pendingOwnerKey] = 'preview|123';
    expect(await pickerFor('cloud:owner-a').recoverLostPhoto(), isNull);
    expect(
      preferences.values.containsKey(DeviceMealPhotoPicker.pendingOwnerKey),
      isFalse,
    );
  });

  test('discard clears only the current owner pending photo marker', () async {
    const marker = 'cloud:owner-a|123';
    preferences.values[DeviceMealPhotoPicker.pendingOwnerKey] = marker;
    await pickerFor('cloud:owner-b').discardPendingPhoto();
    expect(preferences.values[DeviceMealPhotoPicker.pendingOwnerKey], marker);
    await pickerFor('cloud:owner-a').discardPendingPhoto();
    expect(
      preferences.values.containsKey(DeviceMealPhotoPicker.pendingOwnerKey),
      isFalse,
    );
  });

  test(
    'desktop startup never invokes native Android lost-photo recovery',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      preferences.values[DeviceMealPhotoPicker.pendingOwnerKey] = 'preview|123';
      expect(await pickerFor('preview').recoverLostPhoto(), isNull);
      expect(nativePicker.recoveries, 0);
    },
  );
}
