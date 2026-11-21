import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design.dart';

class FloatingDock extends StatelessWidget {
  const FloatingDock({super.key, required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final l = context.l;
    final labels = [l.home, l.library, l.review, l.settings];
    final icons = [
      CupertinoIcons.square_grid_2x2,
      CupertinoIcons.tray,
      CupertinoIcons.sun_max,
      CupertinoIcons.slider_horizontal_3,
    ];
    final c = context.c;
    final scaled = MediaQuery.textScalerOf(context).scale(11) / 11;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.dock,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Semantics(
                key: Key('dock-semantics-$i'),
                onTap: () => onSelect(i),
                label: labels[i],
                selected: i == index,
                button: true,
                excludeSemantics: true,
                child: Tooltip(
                  message: labels[i],
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('dock-$i'),
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => onSelect(i),
                      child: AnimatedScale(
                        scale: i == index ? 1 : .97,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 190),
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 190),
                          constraints: BoxConstraints(
                            minHeight: scaled > 1.5 ? 102 : 64,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 3,
                          ),
                          decoration: BoxDecoration(
                            color: i == index
                                ? c.dockSelected
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icons[i], size: 21, color: c.ink),
                              const SizedBox(height: 5),
                              Text(
                                labels[i],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: i == index
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: c.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
