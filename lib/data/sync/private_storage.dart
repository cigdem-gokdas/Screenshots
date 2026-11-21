import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'vision_recognizer.dart';

/// Startup hook: apply file protection / backup exclusion before the database
/// is created. Never throws (channel missing in tests, non-iOS, picker busy).
Future<void> protectStorageAtLaunch({
  Future<void> Function() protect = preparePrivateSyncStorage,
}) async {
  try {
    await protect();
  } catch (_) {}
}

/// Exclude screenshot copies AND the database containing OCR text from iOS
/// backups before opt-in can start writing imported content.
Future<void> preparePrivateSyncStorage() async {
  if (Platform.isAndroid) {
    await VisionLocalTextRecognizer.channel.invokeMethod<void>(
      'cleanPickerCache',
    );
    return;
  }
  if (!Platform.isIOS) return;
  await VisionLocalTextRecognizer.channel.invokeMethod<void>(
    'cleanPickerCache',
  );
  final documents = await getApplicationDocumentsDirectory();
  final support = await getApplicationSupportDirectory();
  final temporary = await getTemporaryDirectory();
  await VisionLocalTextRecognizer.channel.invokeMethod<void>('protectStorage', {
    'paths': [
      documents.path,
      p.join(support.path, 'imported_screenshots'),
      p.join(temporary.path, 'screenshot_staging'),
    ],
  });
}
