import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required this.readCompleted,
    required this.writeCompleted,
  });
  final Future<bool> Function() readCompleted;
  final Future<void> Function() writeCompleted;
  bool show = false, ready = false;
  Future<void> initialize({required bool existingLibrary}) async {
    final completed = await readCompleted();
    // Existing organized content is never hidden behind a new first-run flow.
    if (existingLibrary && !completed) await writeCompleted();
    show = !completed && !existingLibrary;
    ready = true;
    notifyListeners();
  }

  Future<void> complete() async {
    await writeCompleted();
    show = false;
    notifyListeners();
  }
}
