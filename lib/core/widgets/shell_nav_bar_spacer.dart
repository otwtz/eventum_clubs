import 'package:flutter/material.dart';

import '../constants/shell_layout.dart';

/// Высота как у нижнего плавающего меню — вставляйте в конец [Column] / [ListView], чтобы контент не уходил под бар.
class ShellNavBarSpacer extends StatelessWidget {
  const ShellNavBarSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ShellLayout.navBarSpacerHeight(context));
  }
}
