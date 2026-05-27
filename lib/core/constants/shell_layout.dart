import 'package:flutter/material.dart';

/// Отступы для экранов с плавающим нижним меню [ShellScreen].
abstract final class ShellLayout {
  ShellLayout._();

  /// Высота плашки навигации + кнопка AI в одну линию (иконка + подпись у выбранной вкладки).
  static const double floatingNavBarHeight = 74;

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

  /// Круглая кнопка AI: та же высота, что у плашки навбара ([ShellScreen]).
  static const double aiCoachFabOuterSize = floatingNavBarHeight;

  /// Зазор между правым краем капсулы навбара и кнопкой AI.
  static const double aiCoachFabGapAfterNav = 10;

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
