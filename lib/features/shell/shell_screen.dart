import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: _FloatingBlurNavBar(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (index) => _onItemTapped(index, context),
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
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
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
    }
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Плавающая панель с эффектом blur (стекло).
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
    final blurTint = isDark
        ? scheme.surface.withValues(alpha: 0.42)
        : scheme.surface.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: blurTint,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return Expanded(
                    child: _BlurNavItem(
                      data: item,
                      selected: selected,
                      scheme: scheme,
                      onTap: () => onDestinationSelected(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurNavItem extends StatelessWidget {
  const _BlurNavItem({
    required this.data,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.55);
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: scheme.primary.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: 26,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
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
