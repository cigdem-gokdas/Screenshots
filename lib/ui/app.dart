import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/entry.dart';
import '../l10n/app_localizations.dart';
import 'design.dart';
import 'sync_presentation.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/review_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/details_screen.dart';
import 'screens/import_screen.dart';
import 'screens/editorial_onboarding.dart';
import 'screens/photo_access_section.dart';
import 'floating_dock.dart';
import 'entry_actions.dart';
import 'widgets.dart';

class ScreenshotApp extends StatefulWidget {
  const ScreenshotApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<ScreenshotApp> createState() => _ScreenshotAppState();
}

class _ScreenshotAppState extends State<ScreenshotApp> {
  String? language;
  @override
  void initState() {
    super.initState();
    language = widget.controller.language;
    widget.controller.addListener(languageChanged);
  }

  // Only a language change affects MaterialApp (theme follows the system), so
  // every other controller update rebuilds just the screens that read it.
  void languageChanged() {
    if (widget.controller.language != language) {
      setState(() => language = widget.controller.language);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(languageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: widget.controller,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => c.l.appName,
      theme: appTheme(),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: language == null ? null : Locale(language!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      home: AppShell(controller: widget.controller),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int tab = 0;
  late final AnimationController transition;
  late final Animation<double> opacity;
  Timer? timer;

  /// The one "today" clock shared by Daily Review and the Library filter.
  final ValueNotifier<DateTime> clock = ValueNotifier(DateTime.now());
  @override
  void initState() {
    super.initState();
    transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      value: 1,
    );
    opacity = CurvedAnimation(parent: transition, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null) {
      unawaited(
        widget.controller.sync?.setForeground(
          lifecycle == AppLifecycleState.resumed,
        ),
      );
    }
    timer = Timer.periodic(const Duration(minutes: 1), (_) => refreshClock());
  }

  void refreshClock() {
    if (mounted) clock.value = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshClock();
      unawaited(widget.controller.billing?.refresh());
      unawaited(widget.controller.auth?.refresh());
    } else {
      widget.controller.importer?.pause();
    }
    unawaited(
      widget.controller.sync?.setForeground(state == AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    transition.dispose();
    clock.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void selectTab(int value) {
    if (value == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = value);
    if (!MediaQuery.disableAnimationsOf(context)) transition.forward(from: .15);
  }

  void openManual() {
    final importer = widget.controller.importer;
    if (importer == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ImportScreen(service: importer, autoSelect: true),
      ),
    );
  }

  void openImport() {
    final importer = widget.controller.importer;
    if (importer == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ImportScreen(service: importer)),
    );
  }

  void add({EntryCategory? category}) =>
      openEditor(context, widget.controller, category: category);

  void details(Entry entry) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          DetailsScreen(controller: widget.controller, id: entry.id),
    ),
  );

  void collection(EntryCategory? category, EntryStatus? status, bool today) {
    final l = context.l;
    final title = today
        ? l.savedToday
        : category != null
        ? category.label(l)
        : status != null
        ? status.label(l)
        : l.allEntries;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (c) => Scaffold(
          body: ListenableBuilder(
            listenable: Listenable.merge([widget.controller, clock]),
            builder: (_, _) => LibraryScreen(
              entries: widget.controller.entries,
              now: clock.value,
              barTitle: title,
              initialCategory: category,
              initialStatus: status,
              todayOnly: today,
              onEntry: details,
              onAdd: () => add(category: category),
              onRefresh: widget.controller.refresh,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.controller, clock]),
    builder: (context, _) => buildShell(context),
  );

  Widget buildShell(BuildContext context) {
    final l = context.l;
    final controller = widget.controller;
    if (!controller.loading && controller.onboarding?.show == true) {
      return EditorialOnboarding(
        onFinish: () async {
          if (controller.sync?.supported != true) {
            await controller.onboarding!.complete();
            if (mounted) openManual();
            return;
          }
          final choice = await photoPrePrompt(context);
          if (choice == null) return;
          if (choice) await controller.sync?.enable(includeExisting: true);
          await controller.onboarding!.complete();
          if (!choice && mounted) openManual();
        },
      );
    }
    final now = clock.value;
    final pages = controller.loading || controller.failed
        ? const <Widget>[]
        : [
            HomeScreen(
              entries: controller.entries,
              onCategory: (c) => collection(c, null, false),
              onReview: () => selectTab(2),
              onAdd: add,
              onImport: controller.importer == null ? null : openImport,
              onRefresh: controller.refresh,
              syncStatus: controller.sync == null
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PhotoAccessSection(
                          sync: controller.sync!,
                          onManual: openManual,
                          compact: true,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _SyncPill(
                            label: syncLabel(controller.sync!, l),
                            onTap: () => selectTab(3),
                          ),
                        ),
                      ],
                    ),
            ),
            LibraryScreen(
              entries: controller.entries,
              now: now,
              onEntry: details,
              onAdd: add,
              onRefresh: controller.refresh,
            ),
            ReviewScreen(
              entries: controller.entries,
              now: now,
              onEntry: details,
              onFilter: collection,
              onAdd: add,
              onRefresh: controller.refresh,
            ),
            SettingsScreen(controller: controller),
          ];
    return Scaffold(
      extendBody: true,
      body: controller.loading
          ? CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                const AppSliverBar(),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pageGutter(context),
                    16,
                    pageGutter(context),
                    pageBottomPadding(context),
                  ),
                  sliver: const SliverToBoxAdapter(child: SkeletonList()),
                ),
              ],
            )
          : controller.failed
          ? SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.loadError),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: controller.initialize,
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : FadeTransition(
              opacity: opacity,
              child: IndexedStack(index: tab, children: pages),
            ),
      bottomNavigationBar: FloatingDock(index: tab, onSelect: selectTab),
    );
  }
}

/// Compact tonal pill with a chevron that opens the sync settings.
class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.accentTint,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.arrow_2_circlepath,
                  size: 15,
                  color: c.accent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(CupertinoIcons.chevron_right, size: 12, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
