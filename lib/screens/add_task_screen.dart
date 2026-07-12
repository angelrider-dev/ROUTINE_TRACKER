import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

/// Animations (see docs/animation-reference/05-calendar-form-interactions.png):
/// - screen presents via slide-up + fade (handled by go_router's
///   CustomTransitionPage in lib/router/app_router.dart — not here)
/// - category chips: tint fade + scale bounce on selection
/// - custom-recurrence day toggles: grow in with AnimatedSize, not pop-in
/// - Save button: 3D press-depth (scale 0.97 + perspective tilt, elasticOut)
/// All motion is skipped/instant when Reduce Motion is enabled.
class AddTaskScreen extends ConsumerStatefulWidget {
  final RoutineTask? existingTask;
  const AddTaskScreen({super.key, this.existingTask});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  late final TextEditingController _titleController;
  late TaskCategory _category;
  late RecurrenceType _recurrence;
  late Set<int> _customDays;
  TimeOfDay? _scheduledTime;
  late bool _isHabit;
  late bool _reminderEnabled;

  /// Only meaningful (and only shown in the UI) when [_recurrence] is
  /// [RecurrenceType.oneOff] — the specific calendar day this one-off task
  /// is scheduled for. Defaults to today for new tasks, or the original
  /// task's date when editing.
  late DateTime _oneOffDate;

  late final String _initialSnapshot;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _category = t?.category ?? TaskCategory.fitness;
    _recurrence = t?.recurrence ?? RecurrenceType.daily;
    _customDays = (t?.customDays ?? const []).toSet();
    _scheduledTime = t?.scheduledTime;
    _oneOffDate = t?.createdAt ?? DateTime.now();
    _isHabit = t?.isHabit ?? true;
    _reminderEnabled = t?.reminderEnabled ?? false;
    _initialSnapshot = _snapshot();
    _titleController.addListener(() => setState(() {}));
  }

  String _snapshot() =>
      '${_titleController.text.trim()}|$_category|$_recurrence|${(_customDays.toList()..sort())}|'
      '${_scheduledTime?.hour}:${_scheduledTime?.minute}|$_isHabit|$_reminderEnabled|'
      '${_recurrence == RecurrenceType.oneOff ? _oneOffDate.toIso8601String().split('T').first : ''}';

  bool get _isDirty => _snapshot() != _initialSnapshot;
  bool get _titleValid => _titleController.text.trim().isNotEmpty;
  bool get _recurrenceValid => _recurrence != RecurrenceType.custom || _customDays.isNotEmpty;
  bool get _canSave => _titleValid && _recurrenceValid && !_saving;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (!_isDirty) {
      Navigator.of(context).maybePop();
      return;
    }
    final palette = context.palette;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes to this task.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            autofocus: true,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Discard', style: TextStyle(color: palette.coralAccent)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    final task = RoutineTask(
      id: widget.existingTask?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      // For recurring tasks, this is purely the creation date — preserved
      // across edits since History/Stats exclude days before a task
      // existed from its completion-rate math. For one-off tasks it also
      // doubles as the actual scheduled day, so it comes from the date
      // picker instead of always defaulting to "today".
      createdAt: _recurrence == RecurrenceType.oneOff
          ? _oneOffDate
          : (widget.existingTask?.createdAt ?? DateTime.now()),
      recurrence: _recurrence,
      customDays: _recurrence == RecurrenceType.custom ? _customDays.toList() : null,
      scheduledTime: _scheduledTime,
      isHabit: _isHabit,
      reminderEnabled: _reminderEnabled && _scheduledTime != null,
    );

    final actions = ref.read(taskActionsProvider);
    final bool reminderOk;
    if (_isEditing) {
      reminderOk = await actions.updateTask(task);
    } else {
      reminderOk = await actions.addTask(task);
    }

    if (mounted) {
      if (task.reminderEnabled && !reminderOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Task saved, but the reminder couldn't be scheduled. "
              'Check notification permissions in Settings.',
            ),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        title: const Text('Delete task?'),
        content: Text('"${widget.existingTask!.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            autofocus: true,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: palette.coralAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(taskActionsProvider).removeTask(widget.existingTask!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _scheduledTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _pickOneOffDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _oneOffDate.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _oneOffDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _oneOffDate = picked);
  }

  static String _formatOneOffDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickRecurrence() async {
    final palette = context.palette;
    final picked = await showModalBottomSheet<RecurrenceType>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RecurrenceType.values.map((r) {
            return ListTile(
              title: Text(_recurrenceLabel(r)),
              trailing: r == _recurrence ? Icon(Icons.check, color: palette.purpleAccent) : null,
              onTap: () => Navigator.of(context).pop(r),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _recurrence = picked);
  }

  static String _recurrenceLabel(RecurrenceType r) {
    switch (r) {
      case RecurrenceType.oneOff:
        return 'One-off';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekdays:
        return 'Weekdays';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PopScope(
      canPop: !_isDirty,
onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleClose();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: palette.textMuted),
                      onPressed: _handleClose,
                    ),
                    Text(_isEditing ? 'Edit task' : 'New task',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    _SaveButton(enabled: _canSave, saving: _saving, onPressed: _save),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          autofocus: !_isEditing,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Task name',
                            border: UnderlineInputBorder(borderSide: BorderSide(color: palette.border)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.purpleAccent)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('CATEGORY',
                            style: TextStyle(fontSize: 11, letterSpacing: 0.3, color: palette.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: TaskCategory.values
                              .map((cat) => _AnimatedCategoryChip(
                                    category: cat,
                                    selected: cat == _category,
                                    onTap: () => setState(() => _category = cat),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        _FormRow(
                          icon: Icons.repeat,
                          label: 'Repeat',
                          value: _recurrenceLabel(_recurrence),
                          onTap: _pickRecurrence,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: _recurrence == RecurrenceType.custom
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                                  child: Wrap(
                                    spacing: 6,
                                    children: List.generate(7, (i) {
                                      final day = i + 1;
                                      final label = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
                                      final selected = _customDays.contains(day);
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          selected ? _customDays.remove(day) : _customDays.add(day);
                                        }),
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: selected ? palette.purpleAccent : palette.surfaceRaised,
                                          child: Text(label,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: selected ? palette.background : palette.textSecondary)),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: _recurrence == RecurrenceType.oneOff
                              ? _FormRow(
                                  icon: Icons.event,
                                  label: 'Date',
                                  value: _formatOneOffDate(_oneOffDate),
                                  onTap: _pickOneOffDate,
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (_recurrence == RecurrenceType.custom && _customDays.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Select at least one day',
                                style: TextStyle(fontSize: 11, color: palette.coralAccent)),
                          ),
                        _FormRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _scheduledTime?.format(context) ?? 'None',
                          onTap: _pickTime,
                        ),
                        _ToggleRow(
                          icon: Icons.local_fire_department,
                          label: 'Track as habit',
                          value: _isHabit,
                          onChanged: (v) => setState(() => _isHabit = v),
                        ),
                        _ToggleRow(
                          icon: Icons.notifications,
                          label: 'Reminder',
                          value: _reminderEnabled,
                          enabled: _scheduledTime != null,
                          hint: _scheduledTime == null ? 'Set a time to enable reminders' : null,
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 32),
                          Center(
                            child: TextButton.icon(
                              onPressed: _confirmDelete,
                              icon: Icon(Icons.delete_outline, size: 16, color: palette.coralAccent),
                              label: Text('Delete task', style: TextStyle(color: palette.coralAccent)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
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

class _SaveButton extends StatefulWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback onPressed;
  const _SaveButton({required this.enabled, required this.saving, required this.onPressed});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!widget.enabled) return;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      _controller.animateTo(1.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 100));
    }
  }

  void _onTapEnd() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _controller.animateBack(0.0, curve: Curves.elasticOut, duration: const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapCancel: _onTapEnd,
      onTapUp: (_) => _onTapEnd(),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-0.05 * t)
            ..scale(1.0 - (0.03 * t));
          return Transform(transform: matrix, alignment: Alignment.center, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: widget.saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: palette.purpleAccent),
                )
              : Text('Save',
                  style: TextStyle(
                      color: widget.enabled ? palette.purpleAccent : palette.textMuted,
                      fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

class _AnimatedCategoryChip extends StatefulWidget {
  final TaskCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _AnimatedCategoryChip({required this.category, required this.selected, required this.onTap});

  @override
  State<_AnimatedCategoryChip> createState() => _AnimatedCategoryChipState();
}

class _AnimatedCategoryChipState extends State<_AnimatedCategoryChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void didUpdateWidget(covariant _AnimatedCategoryChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cat = widget.category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final bounce = 1.0 + (0.06 * Curves.easeOut.transform(_controller.value));
          return Transform.scale(scale: bounce, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected ? cat.tint(palette) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.selected ? Colors.transparent : palette.border),
          ),
          child: Text(cat.label,
              style: TextStyle(fontSize: 12, color: widget.selected ? cat.text(palette) : palette.textSecondary)),
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _FormRow({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.border, width: 0.5))),
        child: Row(
          children: [
            Icon(icon, size: 17, color: palette.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Semantics(
              label: '$label: $value',
              child: ExcludeSemantics(
                child: Text(value, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final String? hint;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 17, color: enabled ? palette.textSecondary : palette.textMuted),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, color: enabled ? palette.textPrimary : palette.textMuted)),
              const Spacer(),
              Semantics(
                label: '$label, ${value ? 'on' : 'off'}',
                child: Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeThumbColor: palette.purpleAccent,
                ),
              ),
            ],
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(hint!, style: TextStyle(fontSize: 11, color: palette.textMuted)),
          ),
      ],
    );
  }
}