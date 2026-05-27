import 'package:flutter/material.dart';

/// Превью описания: до [collapsedLines] строк, градиентное затухание при обрезке
/// и кнопка «Показать полностью» тем же размером шрифта, жирнее.
class ClubDescriptionSnippet extends StatefulWidget {
  const ClubDescriptionSnippet({
    super.key,
    required this.description,
    required this.showFullLabel,
    required this.showLessLabel,
    this.collapsedLines = 2,
    /// Вызывается перед раскрытием (можно проанимировать высоту листа).
    this.onBeforeExpandSheet,
    /// Если задано, строка «Показать полностью» не меняет внутреннее состояние
    /// после [onBeforeExpandSheet] и вызывает этот колбэк (например, rebuild с другим блоком описания в родителе).
    this.onExpandAlternative,
  });

  final String description;
  final String showFullLabel;
  final String showLessLabel;
  final int collapsedLines;
  final Future<void> Function()? onBeforeExpandSheet;
  final VoidCallback? onExpandAlternative;

  @override
  State<ClubDescriptionSnippet> createState() => _ClubDescriptionSnippetState();
}

class _ClubDescriptionSnippetState extends State<ClubDescriptionSnippet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.description.trim();
    if (t.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final descStyle =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final baseDesc = descStyle.copyWith(color: scheme.onSurfaceVariant, height: 1.35);
    final linkStyle =
        baseDesc.copyWith(fontWeight: FontWeight.w700, height: null);

    if (_expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: baseDesc),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _expanded = false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: scheme.onSurfaceVariant,
            ),
            child: Text(widget.showLessLabel, style: linkStyle),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        var truncates = false;
        if (w.isFinite && w > 0) {
          final tp = TextPainter(
            text: TextSpan(text: t, style: baseDesc),
            maxLines: widget.collapsedLines,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: w);
          truncates =
              tp.didExceedMaxLines || tp.computeLineMetrics().length > widget.collapsedLines;
        }

        final textWidget = Text(
          t,
          maxLines: widget.collapsedLines,
          overflow: TextOverflow.clip,
          style: baseDesc,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (truncates)
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ).createShader(bounds),
                child: textWidget,
              )
            else
              textWidget,
            if (truncates) ...[
              const SizedBox(height: 2),
              TextButton(
                onPressed: () async {
                  if (widget.onBeforeExpandSheet != null) {
                    await widget.onBeforeExpandSheet!();
                  }
                  if (!mounted) return;
                  if (widget.onExpandAlternative != null) {
                    widget.onExpandAlternative!();
                    return;
                  }
                  setState(() => _expanded = true);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                child: Text(widget.showFullLabel, style: linkStyle),
              ),
            ],
          ],
        );
      },
    );
  }
}
