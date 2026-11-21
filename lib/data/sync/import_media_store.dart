import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'vision_recognizer.dart';

class ImportMediaStore {
  ImportMediaStore({
    Future<Directory> Function()? supportDirectory,
    Future<Directory> Function()? temporaryDirectory,
    Future<void> Function(String path)? protectFile,
  }) : _protect = protectFile ?? _nativeProtect,
       _support = supportDirectory ?? getApplicationSupportDirectory,
       _temporary = temporaryDirectory ?? getTemporaryDirectory;
  final Future<Directory> Function() _support, _temporary;
  final Future<void> Function(String path) _protect;

  static Future<void> _nativeProtect(String path) async {
    if (!Platform.isIOS) return;
    await VisionLocalTextRecognizer.channel.invokeMethod<void>('protectFile', {
      'path': path,
    });
  }

  /// Best effort: explicit iOS file protection on every image we write.
  Future<T> _protected<T extends FileSystemEntity>(T file) async {
    try {
      await _protect(file.path);
    } catch (_) {}
    return file;
  }

  Future<Directory> _directory({bool temporary = false}) async {
    final root = await (temporary ? _temporary() : _support());
    final directory = Directory(
      p.join(
        root.path,
        temporary ? 'screenshot_staging' : 'imported_screenshots',
      ),
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> stage(String key, Uint8List bytes, {bool png = false}) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key) ||
        bytes.isEmpty ||
        bytes.length > 8 * 1024 * 1024) {
      throw ArgumentError('Invalid local image');
    }
    final path = p.join(
      (await _directory(temporary: true)).path,
      '$key.${png ? 'png' : 'jpg'}',
    );
    if (await FileSystemEntity.isLink(path)) {
      throw ArgumentError('Invalid image path');
    }
    return _protected(await File(path).writeAsBytes(bytes, flush: true));
  }

  Future<String> retain(String key, File staged) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key) ||
        !['.jpg', '.png'].contains(p.extension(staged.path))) {
      throw ArgumentError('Invalid image path');
    }
    final name = '$key${p.extension(staged.path)}';
    await _protected(
      await staged.copy(p.join((await _directory()).path, name)),
    );
    return name;
  }

  Future<File?> image(String? name) async {
    if (name == null ||
        p.basename(name) != name ||
        !RegExp(r'^[a-f0-9]{64}\.(jpg|png)$').hasMatch(name)) {
      return null;
    }
    final file = File(p.join((await _directory()).path, name));
    if (await FileSystemEntity.isLink(file.path)) return null;
    return await file.exists() ? file : null;
  }

  Future<void> remove(String? name) async {
    final file = await image(name);
    if (file != null) await file.delete();
  }

  Future<void> clearStaging() async {
    final directory = await _directory(temporary: true);
    await for (final file in directory.list()) {
      if (file is File) await file.delete();
    }
  }

  Future<void> sweep(Future<bool> Function(String) referenced) async {
    final directory = await _directory();
    await for (final file in directory.list()) {
      if (file is File && !await referenced(p.basename(file.path))) {
        await file.delete();
      }
    }
  }

  Future<void> deleteAll() async {
    for (final temporary in [false, true]) {
      final directory = await _directory(temporary: temporary);
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }
}
