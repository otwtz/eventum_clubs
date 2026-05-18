import 'package:flutter/material.dart';

/// Отступы для экранов с плавающим нижним меню [ShellScreen].
abstract final class ShellLayout {
  ShellLayout._();

  /// Вертикальные отступы внутри панели + иконка + подпись (приблизительно).
  static const double floatingNavBarHeight = 72;

  /// Нижний отступ Positioned у плавающей панели в [ShellScreen].
  static const double floatingNavBottomMargin = 16;

  /// Доп. зазор между контентом и верхним краем панели.
  static const double contentGapAboveNav = 8;

  /// Высота зазора под плавающую навигацию (для [SizedBox] в конце списка / колонки на экране).
  static double navBarSpacerHeight(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    return floatingNavBottomMargin +
        safe +
        floatingNavBarHeight +
        contentGapAboveNav;
  }

  /// Нижний inset для snackbar и пр. (как [navBarSpacerHeight]).
  static double contentBottomPadding(BuildContext context) =>
      navBarSpacerHeight(context);

  /// Запас только под плавающую панель (без [MediaQuery.padding.bottom]).
  /// Для контентаInside [SafeArea] в модалках.
  static double floatingNavClearancePadding(BuildContext context) =>
      floatingNavBottomMargin + floatingNavBarHeight + contentGapAboveNav;

  /// [SnackBarBehavior.floating]: отступ снизу относительно края экрана.
  static EdgeInsets snackBarMargin(BuildContext context) {
    return EdgeInsets.fromLTRB(16, 0, 16, navBarSpacerHeight(context) + 8);
  }
}
