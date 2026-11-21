import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../importing/selected_import.dart';
import '../design.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.service,
    this.autoSelect = false,
  });
  final SelectedImportService service;
  final bool autoSelect;
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportSummary? summary;
  @override
  void initState() {
    super.initState();
    if (widget.autoSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) select();
      });
    }
  }

  Future<void> select() async {
    final result = await widget.service.import();
    if (mounted) setState(() => summary = result);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.service,
    builder: (context, _) {
      final l = context.l;
      return Scaffold(
        appBar: AppBar(title: Text(l.importScreenshots)),
        body: SafeArea(
          child: PageBody(
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: context.c.accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.pickerHeadline,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Text(l.pickerExplanation, style: const TextStyle(height: 1.9)),
              const SizedBox(height: 16),
              Text(
                l.pickerLimits,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              FilledButton(
                key: const Key('choose-screenshots'),
                onPressed: widget.service.busy ? null : select,
                child: Text(l.chooseScreenshots),
              ),
              if (widget.service.busy) ...[
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                Text(l.importWorking),
                TextButton(
                  onPressed: widget.service.cancel,
                  child: Text(l.cancel),
                ),
              ],
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l.importSummary(
                        summary!.imported,
                        summary!.duplicates,
                        summary!.skipped,
                        summary!.failed,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
