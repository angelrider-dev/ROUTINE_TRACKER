import 'package:flutter/material.dart';

/// Staggered fade+slide-up entrance, delayed by [index] * 40ms. Used
/// anywhere a list is meant to read as "browse and admire" rather than
/// "scan for action" — see docs/animation-reference/03-habits-loadin...
/// Respects Reduce Motion: jumps straight to the settled state if enabled.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final int delayPerItemMs;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItemMs = 40,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      Future.delayed(Duration(milliseconds: widget.delayPerItemMs * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
