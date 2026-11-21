import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:screenshot_cehennemi/importing/selected_import.dart';

void main() {
  late Directory temp, outside;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tmp_root');
    outside = await Directory.systemTemp.createTemp('outside');
    await Directory(p.join(temp.path, 'selected_imports')).create();
  });
  tearDown(() async {
    await temp.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  test(
    'accepts only files within the real selected_imports directory',
    () async {
      final good = await File(p.join(temp.path, 'selected_imports', 'a.source'))
          .create();
      expect(await isInsideSelectedImports(good.path, temp), isTrue);
      // Same parent folder name, but under a different root.
      await Directory(p.join(outside.path, 'selected_imports')).create();
      final decoy = await File(p.join(outside.path, 'selected_imports', 'a'))
          .create();
      expect(await isInsideSelectedImports(decoy.path, temp), isFalse);
      // Traversal.
      final victim = await File(p.join(temp.path, 'victim')).create();
      expect(
        await isInsideSelectedImports(
          p.join(temp.path, 'selected_imports', '..', 'victim'),
          temp,
        ),
        isFalse,
      );
      expect(await victim.exists(), isTrue);
    },
  );

  test('rejects symlinks pointing outside and discard keeps targets', () async {
    final target = await File(p.join(outside.path, 'secret')).create();
    final link = Link(p.join(temp.path, 'selected_imports', 'l.source'));
    await link.create(target.path);
    expect(await isInsideSelectedImports(link.path, temp), isFalse);
    final picker = SystemImagePicker(tempRoot: () async => temp);
    await picker.discard(link.path);
    expect(await target.exists(), isTrue);
    final good = await File(p.join(temp.path, 'selected_imports', 'b.source'))
        .create();
    await picker.discard(good.path);
    expect(await good.exists(), isFalse);
  });
}
