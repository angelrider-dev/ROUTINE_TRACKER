import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated progress ring. Whenever [progress] changes, the arc sweeps
/// from its previous value to the new one — it never just snaps — and
/// the percentage label counts up in lockstep with the arc.
///
/// Timing follows the project's "Emphasis" token: 500-700ms,
/// Curves.easeOutBack (see docs/animation-reference/02-timing-tokens...).
/// Respects Reduce Motion: if the platform has animations disabled, the
/// ring jumps straight to its end state with no tween.
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;

  const ProgressRing({super.key, required this.progress, this.size = 52});

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _arc;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _arc = _buildTween(0, widget.progress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(widget.progress));
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animateTo(widget.progress, from: oldWidget.progress);
    }
  }

  void _animateTo(double target, {double? from}) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _previousProgress = from ?? _previousProgress;

    if (reduceMotion) {
      setState(() {
        _arc = AlwaysStoppedAnimation(target);
        _previousProgress = target;
      });
      return;
    }

    _arc = _buildTween(_previousProgress, target);
    _controller
      ..reset()
      ..forward();
    _previousProgress = target;
  }

  Animation<double> _buildTween(double from, double to) {
    return Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _arc,
      builder: (context, _) {
        final sweep = _arc.value.clamp(0.0, 1.0);
        final label = (_arc.value.clamp(0.0, 1.0) * 100).round();
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(progress: sweep, track: palette.ringTrack, fill: palette.purpleAccent),
            child: Center(
              child: Text(
                '$label%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.purpleText),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color fill;
  _RingPainter({required this.progress, required this.track, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.track != track || oldDelegate.fill != fill;
}
