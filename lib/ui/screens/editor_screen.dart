import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entry_repository.dart';
import '../../domain/entry.dart';
import '../design.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.repository,
    this.entry,
    this.category,
  });
  final EntryRepository repository;
  final Entry? entry;
  final EntryCategory? category;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, description, url;
  late EntryCategory category;
  late EntryStatus status;
  bool busy = false;
  bool saved = false;
  bool get dirty =>
      title.text != (widget.entry?.title ?? '') ||
      description.text != (widget.entry?.description ?? '') ||
      url.text != (widget.entry?.url ?? '') ||
      category !=
          (widget.entry?.category ??
              widget.category ??
              EntryCategory.watchlist) ||
      status != (widget.entry?.status ?? EntryStatus.todo);
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.entry?.title);
    description = TextEditingController(text: widget.entry?.description);
    url = TextEditingController(text: widget.entry?.url);
    category =
        widget.entry?.category ?? widget.category ?? EntryCategory.watchlist;
    status = widget.entry?.status ?? EntryStatus.todo;
    for (final controller in [title, description, url]) {
      controller.addListener(changed);
    }
  }

  void changed() => setState(() {});
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    url.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (busy) return;
    final navigator = Navigator.of(context);
    if (!dirty || saved) {
      navigator.pop();
      return;
    }
    final l = context.l;
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.discardTitle),
        content: Text(l.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => saved = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.pop();
      });
    }
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await widget.repository.save(
        EntryDraft(
          title: title.text,
          category: category,
          description: description.text,
          url: url.text,
          status: status,
        ),
        id: widget.entry?.id,
      );
      HapticFeedback.lightImpact();
      if (mounted) {
        setState(() {
          saved = true;
          busy = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        showError(context, context.l.saveError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return PopScope(
      canPop: (!dirty || saved) && !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l.cancel,
            onPressed: busy ? null : leave,
            icon: const Icon(CupertinoIcons.xmark, size: 20),
          ),
          title: Text(
            widget.entry == null ? l.newEntry : l.editEntry,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: Form(
          key: form,
          child: PageBody(
            children: [
              const SizedBox(height: 12),
              Text(l.editorSubtitle, style: TextStyle(color: context.c.muted)),
              const SizedBox(height: 30),
              _label(l.titleLabel),
              TextFormField(
                key: const Key('entry-title'),
                controller: title,
                enabled: !busy,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.titleHint,
                  counterText: '',
                ),
                validator: (v) =>
                    EntryDraft.validTitle(v ?? '') ? null : l.titleError,
              ),
              const SizedBox(height: 22),
              _label(l.categoryLabel),
              DropdownButtonFormField<EntryCategory>(
                initialValue: category,
                isExpanded: true,
                items: EntryCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, color: c.color, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              c.label(l),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy ? null : (v) => setState(() => category = v!),
              ),
              const SizedBox(height: 22),
              _label(l.descriptionLabel),
              TextFormField(
                key: const Key('entry-description'),
                controller: description,
                enabled: !busy,
                minLines: 3,
                maxLines: 6,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.descriptionHint,
                  counterText: '',
                ),
                validator: (v) =>
                    (v?.trim().length ?? 0) <= 5000 ? null : l.descriptionError,
              ),
              const SizedBox(height: 22),
              _label(l.urlLabel),
              TextFormField(
                key: const Key('entry-url'),
                controller: url,
                enabled: !busy,
                maxLength: 2048,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: l.urlHint,
                  counterText: '',
                ),
                validator: (v) =>
                    EntryDraft.validUrl(v ?? '') ? null : l.urlError,
              ),
              const SizedBox(height: 22),
              _label(l.statusLabel),
              DropdownButtonFormField<EntryStatus>(
                initialValue: status,
                items: EntryStatus.values
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text(s.label(l))),
                    )
                    .toList(),
                onChanged: busy ? null : (v) => setState(() => status = v!),
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('save-entry'),
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
