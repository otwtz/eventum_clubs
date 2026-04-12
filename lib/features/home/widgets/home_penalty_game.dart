import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Мини-игра «пенальти»: тап по воротам, вратарь отбивает попадание в свою зону.
class HomePenaltyGame extends StatefulWidget {
  const HomePenaltyGame({super.key});

  @override
  State<HomePenaltyGame> createState() => _HomePenaltyGameState();
}

class _HomePenaltyGameState extends State<HomePenaltyGame>
    with SingleTickerProviderStateMixin {
  static const double _keeperWidthN = 0.28;
  static const double _ballRadiusN = 0.052;

  late final AnimationController _shot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  Animation<Offset>? _ballFlight;
  final math.Random _rng = math.Random();

  int _goals = 0;
  int _saves = 0;
  bool _busy = false;
  double _keeperX = 0.5;
  double _targetX = 0.5;
  _ShotResult? _resultFlash;

  @override
  void initState() {
    super.initState();
    _shot.addStatusListener(_onShotStatus);
    _keeperX = 0.12 + _rng.nextDouble() * 0.76;
  }

  @override
  void dispose() {
    _shot.removeStatusListener(_onShotStatus);
    _shot.dispose();
    super.dispose();
  }

  void _onShotStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    final gkL = _keeperX - _keeperWidthN / 2;
    final gkR = _keeperX + _keeperWidthN / 2;
    final hit =
        _targetX + _ballRadiusN >= gkL && _targetX - _ballRadiusN <= gkR;

    if (!mounted) return;

    setState(() {
      if (hit) {
        _saves++;
        _resultFlash = _ShotResult.save;
        HapticFeedback.selectionClick();
      } else {
        _goals++;
        _resultFlash = _ShotResult.goal;
        HapticFeedback.mediumImpact();
      }
      _busy = false;
      _keeperX = 0.12 + _rng.nextDouble() * 0.76;
    });
    _shot.reset();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _resultFlash = null);
    });
  }

  void _shoot(double tapXN) {
    if (_busy || !mounted) return;
    final x = tapXN.clamp(0.06, 0.94);
    setState(() {
      _busy = true;
      _targetX = x;
      _resultFlash = null;
    });

    _ballFlight = Tween<Offset>(
      begin: const Offset(0.5, 0.86),
      end: Offset(x, 0.13),
    ).animate(CurvedAnimation(parent: _shot, curve: Curves.easeOutCubic));

    _shot.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Icon(Icons.sports_soccer, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.homePenaltyGameTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l10n.homePenaltyGameScore(_goals, _saves),
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              l10n.homePenaltyGameHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: AspectRatio(
              aspectRatio: 1.05,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  const pad = 18.0;
                  final innerW = math.max(1.0, w - 2 * pad);
                  final kLeft =
                      pad +
                      innerW *
                          (_keeperX - _keeperWidthN / 2).clamp(
                            0.0,
                            1.0 - _keeperWidthN,
                          );
                  final kW = innerW * _keeperWidthN;

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PitchPainter(scheme: scheme),
                        ),
                      ),
                      Positioned(
                        top: h * 0.07,
                        left: pad,
                        width: innerW,
                        height: h * 0.34,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            final x = d.localPosition.dx / innerW;
                            _shoot(x);
                          },
                          child: CustomPaint(
                            painter: _GoalFrontPainter(scheme: scheme),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        top: h * 0.29,
                        left: kLeft,
                        width: kW,
                        height: h * 0.11,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.tertiary.withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6),
                            ),
                            border: Border.all(
                              color: scheme.onTertiary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: h * 0.08,
                              color: scheme.onTertiary,
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _shot,
                        builder: (context, child) {
                          final flight = _ballFlight;
                          final pos = (_busy && flight != null)
                              ? flight.value
                              : const Offset(0.5, 0.86);
                          final bx = pad + innerW * pos.dx - 18;
                          final by = h * pos.dy - 18;
                          return Positioned(
                            left: bx,
                            top: by,
                            child: Icon(
                              Icons.sports_soccer,
                              size: 36,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (_resultFlash != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color:
                                    (_resultFlash == _ShotResult.goal
                                            ? scheme.primary
                                            : scheme.error)
                                        .withValues(alpha: 0.18),
                              ),
                              child: Center(
                                child: Text(
                                  _resultFlash == _ShotResult.goal
                                      ? l10n.homePenaltyGameGoal
                                      : l10n.homePenaltyGameSave,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _resultFlash == _ShotResult.goal
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShotResult { goal, save }

class _PitchPainter extends CustomPainter {
  _PitchPainter({required this.scheme});

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final grass = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF388E3C),
          Color.lerp(const Color(0xFF2E7D32), scheme.surface, 0.08)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(r, grass);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    canvas.drawLine(
      Offset(midX, size.height * 0.42),
      Offset(midX, size.height * 0.98),
      line,
    );
    canvas.drawCircle(
      Offset(midX, size.height * 0.72),
      size.width * 0.09,
      line,
    );

    final box = RRect.fromRectXY(
      Rect.fromCenter(
        center: Offset(midX, size.height * 0.88),
        width: size.width * 0.55,
        height: size.height * 0.16,
      ),
      4,
      4,
    );
    canvas.drawRRect(box, line);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.scheme != scheme;
}

class _GoalFrontPainter extends CustomPainter {
  _GoalFrontPainter({required this.scheme});

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final post = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(frame, post);

    final net = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    const step = 14.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), net);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), net);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalFrontPainter oldDelegate) =>
      oldDelegate.scheme != scheme;
}
