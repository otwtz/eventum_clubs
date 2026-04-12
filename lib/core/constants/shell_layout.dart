import 'package:flutter/material.dart';

/// Отступы для экранов внутри [ShellScreen] с плавающим нижним меню.
abstract final class ShellLayout {
  ShellLayout._();

  /// Вертикальные отступы внутри панели + иконка + подпись (приблизительно).
  static const double floatingNavBarHeight = 72;

  /// Нижний отступ Positioned у плавающей панели в [ShellScreen].
  static const double floatingNavBottomMargin = 16;

  /// Доп. зазор между контентом и верхним краем панели.
  static const double contentGapAboveNav = 8;

  /// Нижний `padding` для контента под плавающим меню (не перекрывать вкладки/списки).
  static double contentBottomPadding(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    return floatingNavBottomMargin +
        safe +
        floatingNavBarHeight +
        contentGapAboveNav;
  }
}
