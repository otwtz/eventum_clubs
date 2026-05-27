import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/shell_layout.dart';
import '../../core/l10n/app_localizations.dart';

/// Как у системного таб-бара iOS: плавное «перетекание» и лёгкий овершут при смене вкладки.
const Cubic _kTabSpringCurve = Cubic(0.25, 0.92, 0.2, 1.06);

/// Персональный «нажатие» на иконку (слегка сжимается и отскакивает).
const Duration _kPressIn = Duration(milliseconds: 90);
const Duration _kPressOut = Duration(milliseconds: 220);

/// Появление/скрытие подписи вкладки (анимация высоты столбца).
const Duration _kNavLabelRevealDuration = Duration(milliseconds: 400);

/// Пятый пункт нижней навигации — AI (куда ведёт FAB; в капсуле — только 4 слота).
const int _kShellNavAiIndex = 4;

/// Обводка «стеклянной» капсулы навбара и кнопки AI (одинаково в светлой/тёмной теме).
Color _floatingNavGlassBorderColor(bool isDark) => isDark
    ? Colors.white.withValues(alpha: 0.14)
    : Colors.white.withValues(alpha: 0.58);

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navIndex = _shellNavIndex(context);
    final aiRouteActive = navIndex == _kShellNavAiIndex;
    final navRowHeight = ShellLayout.floatingNavBarHeight;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            left: ShellLayout.floatingNavBottomMargin,
            right: ShellLayout.floatingNavBottomMargin,
            bottom: ShellLayout.floatingNavBottomMargin + bottomInset,
            height: navRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FloatingBlurNavBar(
                    selectedIndex: navIndex,
                    onDestinationSelected: (index) =>
                        _onItemTapped(index, context),
                    items: [
                      _NavItemData(
                        icon: Icons.newspaper_outlined,
                        selectedIcon: Icons.newspaper,
                        label: l10n.news,
                      ),
                      _NavItemData(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: l10n.home,
                        iconGlyphScale: 1.1,
                      ),
                      _NavItemData(
                        icon: Icons.map_outlined,
                        selectedIcon: Icons.map,
                        label: l10n.map,
                      ),
                      _NavItemData(
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person,
                        label: l10n.profile,
                      ),
                    ],
                    scheme: scheme,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: ShellLayout.aiCoachFabGapAfterNav),
                SizedBox(
                  width: navRowHeight,
                  child: _AiCoachGlassFab(
                    scheme: scheme,
                    isDark: isDark,
                    isIos: Theme.of(context).platform == TargetPlatform.iOS,
                    extent: navRowHeight,
                    selected: aiRouteActive,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _onItemTapped(_kShellNavAiIndex, context);
                    },
                    label: l10n.aiCoachFabLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Индекс активного пункта: **0–3** — вкладки в капсуле, **`_kShellNavAiIndex`** — AI (FAB).
  int _shellNavIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/ai-coaches')) return _kShellNavAiIndex;
    if (location.startsWith('/news')) return 0;
    if (location.startsWith('/home')) return 1;
    if (location.startsWith('/club')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/news');
        break;
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        context.go('/profile');
        break;
      case _kShellNavAiIndex:
        context.go('/ai-coaches');
        break;
      default:
        break;
    }
  }
}

/// Круглая кнопка «AI» в том же «стеклянном» стиле, что и нижняя панель.
class _AiCoachGlassFab extends StatelessWidget {
  const _AiCoachGlassFab({
    required this.scheme,
    required this.isDark,
    required this.isIos,
    required this.extent,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final ColorScheme scheme;
  final bool isDark;
  final bool isIos;

  /// Сторона квадрата под круг (как высота строки навбара).
  final double extent;

  /// Активен экран AI: внутренний красный диск (как «таблетка» навбара).
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final sigma = isIos ? 28.0 : 22.0;
    final blurTint = isDark
        ? scheme.surface.withValues(alpha: isIos ? 0.34 : 0.42)
        : scheme.surface.withValues(alpha: isIos ? 0.48 : 0.55);
    final d = extent;
    // Как зазор «таблетки» от краёв ячейки в навбаре — эффект вложенности.
    final innerInset = math.max(5.0, d * 0.085);

    final idleIconColor = scheme.onSurface.withValues(
      alpha: isIos ? 0.52 : 0.55,
    );
    final textStyleBase = TextStyle(
      fontSize: isIos ? 17 : 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: d,
          height: d,
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blurTint,
                      border: Border.all(
                        color: _floatingNavGlassBorderColor(isDark),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.42 : 0.14,
                          ),
                          blurRadius: isIos ? 20 : 16,
                          offset: Offset(0, isIos ? 10 : 7),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.all(innerInset),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        style: textStyleBase.copyWith(
                          color: selected ? scheme.primary : idleIconColor,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.iconGlyphScale = 1,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Скейл глифа: у `Icons.home*` в Material Icons визуально меньше запас.
  final double iconGlyphScale;
}

/// Стекло + нижнее меню с анимациями как у таб-бара на iPhone (капсула, пружина, масштаб при нажатии).
class _FloatingBlurNavBar extends StatelessWidget {
  const _FloatingBlurNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.scheme,
    required this.isDark,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavItemData> items;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final sigma = isIos ? 28.0 : 22.0;
    final blurTint = isDark
        ? scheme.surface.withValues(alpha: isIos ? 0.34 : 0.42)
        : scheme.surface.withValues(alpha: isIos ? 0.48 : 0.55);
    final borderColor = _floatingNavGlassBorderColor(isDark);

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: blurTint,
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.14),
                    blurRadius: isIos ? 24 : 20,
                    offset: Offset(0, isIos ? 12 : 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = math.max(items.length, 1);
                    final w = constraints.maxWidth;
                    final cell = w / count;
                    // Ползунок шире (длинные подписи вроде «Профиль»), но не вплотную к соседям.
                    const kPillSideInset = 2.0;
                    final maxPillWidth = math.max(
                      cell - 2 * kPillSideInset,
                      0.0,
                    );
                    final fractionalW = cell * (isIos ? 0.96 : 0.94);
                    final pillW = math.min(
                      math.max(fractionalW, 42.0),
                      maxPillWidth,
                    );
                    final sel = selectedIndex;
                    final pillVisible = sel < items.length;
                    final pillAnchorIdx = pillVisible ? sel : 0;
                    final safeIdx = math.min(
                      math.max(pillAnchorIdx, 0),
                      count - 1,
                    );
                    final left = safeIdx * cell + (cell - pillW) / 2;

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topLeft,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 360),
                          curve: _kTabSpringCurve,
                          left: left,
                          top: 2,
                          bottom: 2,
                          width: pillW,
                          child: AnimatedOpacity(
                            opacity: pillVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: IgnorePointer(
                              ignoring: !pillVisible,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  color: scheme.primary.withValues(
                                    alpha: isDark ? 0.22 : 0.14,
                                  ),
                                  border: Border.all(
                                    color: scheme.primary.withValues(
                                      alpha: isDark ? 0.38 : 0.28,
                                    ),
                                    width: 0.85,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(items.length, (index) {
                                final item = items[index];
                                final selected = index == sel;
                                return Expanded(
                                  child: _AnimatedGlassNavItem(
                                    data: item,
                                    selected: selected,
                                    scheme: scheme,
                                    isIos: isIos,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      onDestinationSelected(index);
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGlassNavItem extends StatefulWidget {
  const _AnimatedGlassNavItem({
    required this.data,
    required this.selected,
    required this.scheme,
    required this.isIos,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final ColorScheme scheme;
  final bool isIos;
  final VoidCallback onTap;

  @override
  State<_AnimatedGlassNavItem> createState() => _AnimatedGlassNavItemState();
}

class _AnimatedGlassNavItemState extends State<_AnimatedGlassNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: _kPressIn,
      reverseDuration: _kPressOut,
      lowerBound: 0,
      upperBound: 1,
    );
    _press.value = 0;
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _press.forward();
  }

  void _onTapUp(_) => _bounceOut();
  void _onTapCancel() => _bounceOut();

  void _bounceOut() {
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final selected = widget.selected;
    final color = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: widget.isIos ? 0.52 : 0.55);

    final pressT = CurvedAnimation(parent: _press, curve: Curves.easeOutCubic);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, child) {
              final pressedScale =
                  1.0 - pressT.value * (widget.isIos ? 0.08 : 0.06);
              final selScale = selected ? (widget.isIos ? 1.04 : 1.02) : 1.0;
              return Transform.scale(
                scale: pressedScale * selScale,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              child: LayoutBuilder(
                builder: (context, c) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: c.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: _kNavLabelRevealDuration,
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.88, end: 1)
                                      .animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              );
                            },
                            // Одинаковый бокс — у домика глиф в шрифте визуально меньше остальных.
                            child: SizedBox(
                              key: ValueKey(
                                '${widget.data.label}_${selected ? 'sel' : 'out'}',
                              ),
                              width: widget.isIos ? 26 : 27,
                              height: widget.isIos ? 26 : 27,
                              child: Center(
                                child: Transform.scale(
                                  scale: widget.data.iconGlyphScale,
                                  child: Icon(
                                    selected
                                        ? widget.data.selectedIcon
                                        : widget.data.icon,
                                    size: widget.isIos ? 24 : 25,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: _kNavLabelRevealDuration,
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            child: selected
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.data.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
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
