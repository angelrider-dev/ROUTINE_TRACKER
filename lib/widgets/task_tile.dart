import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// A single task row.
///
/// Gesture mapping (deliberate, not incidental):
/// - tap anywhere on the row toggles completion — the full row is the tap
///   target (min 44px height) for accessibility, not just the check circle
/// - long-press opens edit — a brief scale-pop + medium haptic confirms
///   the gesture landed BEFORE navigating, so it doesn't feel like an
///   accidental screen change. [onEdit] is optional so this widget stays
///   usable in read-only/preview contexts without forcing navigation.
///
/// Animations (see docs/animation-reference/01-today-progress-ring.png):
/// - check circle: scale pop (~1.15) on completion, 250ms Curves.easeOut
/// - title: strikethrough eases in rather than cutting instantly
/// - haptic: light impact on toggle, medium impact on long-press-to-edit
/// All skipped/instant when Reduce Motion is on.
class TaskTile extends StatefulWidget {
  final RoutineTask task;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.done,
    required this.onToggle,
    this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _pressScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_pressController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleLongPress() async {
    if (widget.onEdit == null) return;
    HapticFeedback.mediumImpact();

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      widget.onEdit!.call();
      return;
    }

    await _pressController.forward(from: 0);
    // Small pause after the bounce settles, not an instant screen-change —
    // gives the confirming pop a moment to actually be seen before the
    // navigation transition takes over.
    await Future.delayed(const Duration(milliseconds: 60));
    if (mounted) widget.onEdit!.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final category = widget.task.category;
    final tint = category.tint(palette);
    final accent = category.accent(palette);
    final text = category.text(palette);

    return Semantics(
      label: '${widget.task.title}, ${widget.done ? 'done' : 'not done'}',
      hint: widget.onEdit != null ? 'Double tap to toggle, long press to edit' : 'Double tap to toggle',
      button: true,
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) => Transform.scale(scale: _pressScale.value, child: child),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onToggle();
            },
            onLongPress: widget.onEdit != null ? _handleLongPress : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _CheckCircle(done: widget.done, accent: accent, background: palette.background),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: text,
                            decoration: widget.done ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                          child: Text(widget.task.title),
                        ),
                        if (widget.task.scheduledTime != null)
                          Text(widget.task.scheduledTime!.format(context),
                              style: TextStyle(fontSize: 11, color: accent)),
                      ],
                    ),
                  ),
                  Icon(category.icon, size: 16, color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatefulWidget {
  final bool done;
  final Color accent;
  final Color background;

  const _CheckCircle({required this.done, required this.accent, required this.background});

  @override
  State<_CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<_CheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _CheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.done && widget.done) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: widget.done
            ? Container(
                key: const ValueKey('done'),
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: widget.accent, shape: BoxShape.circle),
                child: Icon(Icons.check, size: 14, color: widget.background),
              )
            : Container(
                key: const ValueKey('not-done'),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accent, width: 2),
                ),
              ),
      ),
    );
  }
}
