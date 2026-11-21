import 'package:flutter/services.dart';

import '../../sync/sync_models.dart';

/// Apple's Vision framework performs OCR locally without a cloud service or
/// a third-party diagnostics SDK. Native code accepts app-sandbox files only.
class VisionLocalTextRecognizer implements LocalTextRecognizer {
  static const channel = MethodChannel('screenshot_cehennemi/local_vision');
  @override
  Future<String> recognize(String localPath) async =>
      await channel
          .invokeMethod<String>('recognizeText', {'path': localPath})
          .timeout(const Duration(seconds: 45)) ??
      '';
  @override
  Future<void> close() async {}
}
