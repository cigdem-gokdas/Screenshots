import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../l10n/app_localizations.dart';

/// Colour tokens for the light and dark themes. Read them with `context.c`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.accentTint,
    required this.danger,
    required this.dock,
    required this.dockSelected,
  });

  final Color background,
      card,
      ink,
      muted,
      line,
      accent,
      onAccent,
      accentTint,
      danger,
      dock,
      dockSelected;

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    card: Color(0xFFF6F6F7),
    ink: Color(0xFF181818),
    muted: Color(0xFF6B6B6B),
    line: Color(0xFFE9E9EB),
    accent: Color(0xFF7157B8),
    onAccent: Color(0xFFFFFFFF),
    accentTint: Color(0xFFF0ECF7),
    danger: Color(0xFFB14C4C),
    dock: Color(0xFFF1F1F3),
    dockSelected: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    background: Color(0xFF111113),
    card: Color(0xFF1B1B1E),
    ink: Color(0xFFF1F1F2),
    muted: Color(0xFFA3A3AA),
    line: Color(0xFF2B2B30),
    accent: Color(0xFFA995EE),
    onAccent: Color(0xFF17131F),
    accentTint: Color(0xFF2A2442),
    danger: Color(0xFFE8847F),
    dock: Color(0xFF232327),
    dockSelected: Color(0xFF34343A),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      card: mix(card, other.card),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentTint: mix(accentTint, other.accentTint),
      danger: mix(danger, other.danger),
      dock: mix(dock, other.dock),
      dockSelected: mix(dockSelected, other.dockSelected),
    );
  }
}

extension Strings on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  AppColors get c {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
  }
}

extension CategoryDesign on EntryCategory {
  Color get color => const [
    Color(0xFF7157B8),
    Color(0xFFD0803B),
    Color(0xFF427BBA),
    Color(0xFF559A72),
    Color(0xFFB96583),
    Color(0xFFA97737),
    Color(0xFF737A9F),
    Color(0xFF737373),
  ][index];

  /// Category colour adjusted for the current brightness.
  Color tone(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, .32)!
      : color;
  IconData get icon => const [
    CupertinoIcons.film,
    CupertinoIcons.flame,
    CupertinoIcons.book,
    CupertinoIcons.game_controller,
    CupertinoIcons.map,
    CupertinoIcons.bag,
    CupertinoIcons.lightbulb,
    CupertinoIcons.square_grid_2x2,
  ][index];
  String label(AppLocalizations l) => [
    l.watchlist,
    l.recipes,
    l.reading,
    l.gaming,
    l.places,
    l.wishlist,
    l.ideas,
    l.other,
  ][index];
  String hint(AppLocalizations l) => [
    l.watchHint,
    l.recipesHint,
    l.readingHint,
    l.gamingHint,
    l.placesHint,
    l.wishlistHint,
    l.ideasHint,
    l.otherHint,
  ][index];
}

extension StatusDesign on EntryStatus {
  String label(AppLocalizations l) => [l.todo, l.completed, l.archived][index];
  IconData get icon => [
    CupertinoIcons.circle,
    CupertinoIcons.checkmark_circle,
    CupertinoIcons.archivebox,
  ][index];
}

ThemeData appTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final c = dark ? AppColors.dark : AppColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.light.accent,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        secondaryContainer: c.accentTint,
        onSecondaryContainer: c.accent,
        surface: c.background,
        onSurface: c.ink,
        onSurfaceVariant: c.muted,
        outline: c.muted,
        outlineVariant: c.line,
        surfaceContainerLowest: c.background,
        surfaceContainerLow: c.card,
        surfaceContainer: c.card,
        surfaceContainerHigh: c.card,
        surfaceContainerHighest: c.card,
        error: c.danger,
        inverseSurface: dark
            ? const Color(0xFFE8E8EA)
            : const Color(0xFF29292C),
        onInverseSurface: dark ? const Color(0xFF17171A) : Colors.white,
      );
  final radius = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: c.background,
    colorScheme: scheme,
    extensions: [c],
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: c.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        color: c.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: c.ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      actionTextColor: dark ? const Color(0xFF6A52B0) : const Color(0xFFC9BAF5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      contentPadding: const EdgeInsets.all(17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.accent),
      ),
      hintStyle: TextStyle(color: c.muted, fontSize: 14),
    ),
    // Primary: filled accent (colours come from the colour scheme so that
    // FilledButton.tonal keeps its own tonal fill).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(48, 52),
        shape: radius,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    // Tertiary: accent text with a 44pt tap area.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: c.accentTint,
      backgroundColor: c.card,
      side: BorderSide.none,
      labelStyle: TextStyle(fontFamily: 'Manrope', color: c.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.accentTint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}

/// Horizontal page gutter that keeps content at most 700pt wide.
double pageGutter(BuildContext context) =>
    math.max(24, (MediaQuery.sizeOf(context).width - 700) / 2);

/// Bottom padding for scroll content. Under the floating dock the Scaffold
/// reports the dock height as bottom padding (extendBody), so content scrolls
/// behind the dock without being cut off.
double pageBottomPadding(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + 24;

/// Pinned top bar that shrinks from a large brand (or route title) into a slim
/// bar while scrolling down and grows back on scroll up.
class AppSliverBar extends StatelessWidget {
  const AppSliverBar({
    super.key,
    this.title,
    this.collapsedTitle,
    this.actions = const [],
  });

  /// Large title that shrinks into the slim bar (iOS large-title style).
  /// Without any title the bar shows the viewfinder icon and app name.
  final String? title;

  /// Title shown only once the bar has collapsed, for pages whose own
  /// headline is part of the content.
  final String? collapsedTitle;
  final List<Widget> actions;
  static const double _toolbar = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canPop = title != null && (ModalRoute.of(context)?.canPop ?? false);
    final collapsedStart = canPop ? 52.0 : 24.0;
    final large = title != null;
    final base = large ? 17.0 : 13.0;
    final scaleMax = large ? 1.75 : 1.55;
    final expanded = collapsedTitle != null
        ? _toolbar + 8
        : (large ? 96.0 : 108.0);
    return SliverAppBar(
      pinned: true,
      toolbarHeight: _toolbar,
      expandedHeight: expanded,
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: title != null,
      actions: [...actions, const SizedBox(width: 8)],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final t = settings == null
              ? 1.0
              : ((settings.currentExtent - settings.minExtent) /
                        math.max(1, settings.maxExtent - settings.minExtent))
                    .clamp(0.0, 1.0);
          final scale = 1 + (scaleMax - 1) * t;
          final top = MediaQuery.paddingOf(context).top;
          final label = title ?? collapsedTitle ?? context.l.appName;
          return Padding(
            padding: EdgeInsets.only(
              left: collapsedStart + (24 - collapsedStart) * t,
              right: 96 - 72 * t,
              bottom: 15 + 7 * t,
              top: top,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Opacity(
                opacity: collapsedTitle == null ? 1 : (1 - t).clamp(0.0, 1.0),
                child: Semantics(
                  header: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title == null && collapsedTitle == null) ...[
                        Icon(CupertinoIcons.viewfinder, size: 21 * scale),
                        SizedBox(width: 9 * scale),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: base * scale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.25 * scale,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tinted section surface used on the settings page (no borders or dividers).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: context.c.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  );
}

/// Scrollable page body. Tab screens pass [topBar] (an [AppSliverBar]) and an
/// optional [onRefresh] for pull-to-refresh.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.topBar,
    this.onRefresh,
  });
  final List<Widget> children;
  final Widget? topBar;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ?topBar,
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            12,
            gutter,
            pageBottomPadding(context),
          ),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
    return refreshable(context, onRefresh, scroll);
  }
}

Widget refreshable(
  BuildContext context,
  Future<void> Function()? onRefresh,
  Widget child,
) => onRefresh == null
    ? child
    : RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: child,
      );

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: context.c.muted,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.icon = CupertinoIcons.tray,
  });
  final String title, body;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.c.accentTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: context.c.accent),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.c.muted, height: 1.7),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
