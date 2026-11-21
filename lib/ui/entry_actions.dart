import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../application/app_controller.dart';
import '../domain/entry.dart';
import 'design.dart';
import 'screens/editor_screen.dart';

/// Gives widgets deep in a route access to the single [AppController].
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.controller, required super.child});
  final AppController controller;
  static AppController of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.controller;
  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.controller != controller;
}

/// One way to open the editor from every screen.
Future<void> openEditor(
  BuildContext context,
  AppController controller, {
  Entry? entry,
  EntryCategory? category,
}) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => EditorScreen(
      repository: controller.repository,
      entry: entry,
      category: category,
    ),
  ),
);

/// Completes an open entry, or reopens a completed one.
Future<void> toggleDone(BuildContext context, Entry entry) async {
  final controller = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l;
  HapticFeedback.selectionClick();
  try {
    await controller.repository.setStatus(
      entry.id,
      entry.status == EntryStatus.completed
          ? EntryStatus.todo
          : EntryStatus.completed,
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.actionError)));
  }
}

/// Deletes now and offers Undo. The image file is only removed once the
/// snackbar closes without Undo.
Future<void> deleteWithUndo(BuildContext context, Entry entry) async {
  final controller = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l;
  HapticFeedback.lightImpact();
  try {
    await controller.softDelete(entry);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.actionError)));
    return;
  }
  messenger.hideCurrentSnackBar();
  final closed = messenger
      .showSnackBar(
        SnackBar(
          content: Text(l.entryDeleted),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              HapticFeedback.selectionClick();
              try {
                await controller.undoDelete(entry);
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text(l.actionError)));
              }
            },
          ),
        ),
      )
      .closed;
  final reason = await closed;
  if (reason != SnackBarClosedReason.action) {
    await controller.commitDelete(entry);
  }
}

/// Shares title, link and the screenshot file when there is one.
Future<void> shareEntry(BuildContext context, Entry entry) async {
  final controller = AppScope.of(context);
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final text = [entry.title, if (entry.url.isNotEmpty) entry.url].join('\n');
  XFile? file;
  try {
    final image = await controller.media.image(entry.imagePath);
    if (image != null) file = XFile(image.path);
  } catch (_) {
    /* Share the text without the image. */
  }
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: entry.title,
        files: file == null ? null : [file],
        sharePositionOrigin: origin,
      ),
    );
  } catch (_) {
    if (context.mounted) showError(context, context.l.actionError);
  }
}

/// Long-press menu: share, edit, delete.
Future<void> showEntryMenu(BuildContext context, Entry entry) async {
  final l = context.l;
  final controller = AppScope.of(context);
  HapticFeedback.selectionClick();
  const font = TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600);
  final choice = await showCupertinoModalPopup<String>(
    context: context,
    builder: (sheet) => CupertinoActionSheet(
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: font,
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheet, 'share'),
          child: Text(l.share, style: font),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheet, 'edit'),
          child: Text(l.edit, style: font),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(sheet, 'delete'),
          child: Text(l.delete, style: font),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(sheet),
        child: Text(l.cancel, style: font),
      ),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'share':
      await shareEntry(context, entry);
    case 'edit':
      await openEditor(context, controller, entry: entry);
    case 'delete':
      await deleteWithUndo(context, entry);
  }
}
