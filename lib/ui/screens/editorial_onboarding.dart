import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entry.dart';
import '../design.dart';

/// Local vector structures suggest saved fragments without personal/copyrighted
/// images. The pile is an interactive part of the story, not a dashboard demo.
class EditorialOnboarding extends StatefulWidget {
  const EditorialOnboarding({super.key, required this.onFinish});
  final Future<void> Function() onFinish;
  @override
  State<EditorialOnboarding> createState() => _EditorialOnboardingState();
}

class _EditorialOnboardingState extends State<EditorialOnboarding>
    with SingleTickerProviderStateMixin {
  int scene = 0;
  bool busy = false;
  late final AnimationController arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..forward();
  @override
  void dispose() {
    arrival.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (busy) return;
    HapticFeedback.selectionClick();
    if (scene < 2) {
      setState(() => scene++);
      return;
    }
    setState(() => busy = true);
    try {
      await widget.onFinish();
    } catch (_) {
      if (mounted) showError(context, context.l.actionError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: bounds.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.viewfinder, size: 19),
                        const Spacer(),
                        Text(
                          context.l.onboardingProgress(scene + 1, 3),
                          style: TextStyle(
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: context.c.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _art(context, bounds),
                    const SizedBox(height: 36),
                    AnimatedSwitcher(
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: Align(
                        key: ValueKey(scene),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scene == 0
                                  ? l.onboardingSaved
                                  : scene == 1
                                  ? l.onboardingRecognition
                                  : l.onboardingResolution,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (scene == 0) ...[
                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: reduce
                                    ? Duration.zero
                                    : const Duration(milliseconds: 1000),
                                builder: (context, value, child) =>
                                    Opacity(opacity: value, child: child),
                                child: Text(
                                  l.onboardingLost,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: context.c.muted),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FilledButton(
                      key: const Key('onboarding-next'),
                      onPressed: busy ? null : next,
                      child: Text(
                        scene == 2 ? l.organizeHell : l.onboardingNext,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.onboardingGuest,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _art(BuildContext context, BoxConstraints bounds) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final l = context.l;
    final labels = [
      l.semanticWatch,
      l.semanticRead,
      l.semanticGo,
      l.semanticEat,
      l.semanticDo,
    ];
    return Semantics(
      button: true,
      label: l.onboardingNext,
      onTap: next,
      child: GestureDetector(
        onTap: next,
        child: ExcludeSemantics(
          child: SizedBox(
            height: math.min(300, math.max(190, bounds.maxHeight * .43)),
            child: LayoutBuilder(
              builder: (context, area) => AnimatedBuilder(
                animation: arrival,
                builder: (context, _) {
                  final organized = scene > 0;
                  final recognizing = scene == 1;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(6, (i) {
                      final progress = reduce
                          ? 1.0
                          : ((arrival.value - i * .105) / .45).clamp(0.0, 1.0);
                      final width = organized
                          ? area.maxWidth * .29
                          : area.maxWidth * .43;
                      final height = organized
                          ? area.maxHeight * .34
                          : area.maxHeight * .62;
                      final left = recognizing
                          ? [.01, .35, .70, .08, .43, .50][i] * area.maxWidth
                          : organized
                          ? (i % 3) * area.maxWidth * .35
                          : area.maxWidth * (.22 + ((i % 3) - 1) * .075);
                      final top = recognizing
                          ? [.03, .11, .02, .52, .56, .50][i] * area.maxHeight
                          : organized
                          ? (i ~/ 3) * area.maxHeight * .51
                          : area.maxHeight * (.12 + ((i % 4) - 1) * .055);
                      return AnimatedPositioned(
                        duration: reduce
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: left,
                        top: top + (1 - progress) * 26,
                        width: width,
                        height: height + 24,
                        child: Opacity(
                          opacity: progress,
                          child: Column(
                            children: [
                              Expanded(
                                child: AnimatedRotation(
                                  turns: recognizing
                                      ? [
                                          -.018,
                                          .012,
                                          -.01,
                                          .016,
                                          -.012,
                                          .018,
                                        ][i]
                                      : organized
                                      ? 0
                                      : ([
                                          -.055,
                                          .028,
                                          -.018,
                                          .045,
                                          -.035,
                                          .012,
                                        ][i]),
                                  duration: reduce
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  child: _PaperFragment(
                                    index: i,
                                    resolved: scene == 2,
                                  ),
                                ),
                              ),
                              if (organized) ...[
                                const SizedBox(height: 5),
                                Opacity(
                                  opacity: recognizing && i == 5 ? 0 : 1,
                                  child: Text(
                                    scene == 2
                                        ? EntryCategory
                                              .values[[0, 2, 4, 1, 6, 7][i]]
                                              .label(l)
                                        : labels[i.clamp(0, 4)],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: EntryCategory
                                          .values[[0, 2, 4, 1, 6, 7][i]]
                                          .color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperFragment extends StatelessWidget {
  const _PaperFragment({required this.index, required this.resolved});
  final int index;
  final bool resolved;
  @override
  Widget build(BuildContext context) {
    final category = EntryCategory.values[[0, 2, 4, 1, 6, 7][index]];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: resolved
            ? category.color.withValues(alpha: .08)
            : context.c.card,
        borderRadius: BorderRadius.circular(resolved ? 15 : 6),
        border: Border.all(color: context.c.line),
      ),
      child: LayoutBuilder(
        builder: (context, area) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: area.maxHeight * .5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(category.icon, size: 22, color: category.color),
            ),
            const Spacer(),
            Container(
              height: 3,
              width: area.maxWidth * .85,
              color: context.c.line,
            ),
            const SizedBox(height: 5),
            Container(
              height: 3,
              width: area.maxWidth * .56,
              color: context.c.line,
            ),
            const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}
