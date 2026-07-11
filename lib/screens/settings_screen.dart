import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

/// Settings screen. Every change here applies immediately — there's no
/// Save button anywhere on this screen, by design (see spec).
///
/// Animations (see docs/animation-reference/07-settings-theme-crossfade.png):
/// - theme mode change: cross-fades the WHOLE APP via AnimatedTheme,
///   wired in main.dart's MaterialApp.builder — not just this screen
/// - toggle rows: standard Switch animation, no custom work needed
/// - permission grant: a small bell-wiggle + scale confirmation, the one
///   piece of non-utility motion on this screen, because it's confirming
///   a real state change the user needs to notice, not decoration
/// - explicitly NO 3D depth anywhere here
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _remindersOn = true;
  bool _permissionDenied = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    final enabled = await ref.read(notificationServiceProvider).areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _permissionDenied = !enabled;
      _remindersOn = enabled;
      _checkingPermission = false;
    });
  }

  Future<void> _setRemindersEnabled(bool enabled) async {
    final notifications = ref.read(notificationServiceProvider);

    if (!enabled) {
      await notifications.cancelAll();
      setState(() => _remindersOn = false);
      return;
    }

    final alreadyGranted = await notifications.areNotificationsEnabled();
    if (!alreadyGranted) {
      final granted = await _showPermissionExplainer(context);
      if (!granted) {
        setState(() => _permissionDenied = true);
        return;
      }
    }

    setState(() {
      _remindersOn = true;
      _permissionDenied = false;
    });

    // Re-establish notifications for every task that wants one.
    final tasksAsync = ref.read(tasksProvider);
    tasksAsync.whenData((tasks) async {
      for (final task in tasks.where((t) => t.reminderEnabled)) {
        await notifications.rescheduleFor(task);
      }
    });

    HapticFeedback.lightImpact();
  }

  Future<bool> _showPermissionExplainer(BuildContext context) async {
    final palette = context.palette;
    bool granted = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WigglingBellIcon(palette: palette),
                const SizedBox(height: 16),
                Text('Stay on track',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: palette.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  "Get a reminder exactly when a task is due, so nothing slips through.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await ref.read(notificationServiceProvider).requestPermissions();
                      granted = result;
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Enable notifications'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text('Not now', style: TextStyle(color: palette.textMuted)),
                ),
              ],
            ),
          ),
        );
      },
    );

    return granted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: palette.textMuted),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    _SectionLabel('Appearance'),
                    _ThemeModeSelector(
                      currentMode: currentMode,
                      onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode),
                    ),
                    _SectionLabel('Notifications'),
                    if (_checkingPermission)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_permissionDenied)
                      _PermissionDeniedHint(palette: palette)
                    else
                      _ToggleRow(
                        icon: Icons.notifications,
                        label: 'Reminders',
                        value: _remindersOn,
                        onChanged: _setRemindersEnabled,
                      ),
                    _SectionLabel('Data'),
                    _ActionRow(
                      icon: Icons.file_download,
                      label: 'Export data',
                      onTap: () => _exportData(context),
                    ),
                    _SectionLabel('About'),
                    _VersionRow(palette: palette),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final tasksAsync = ref.read(tasksProvider);
    final completionsAsync = ref.read(completionsProvider);

    final tasks = tasksAsync.valueOrNull;
    final completions = completionsAsync.valueOrNull;

    if (tasks == null || completions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data isn't ready yet — try again in a moment")),
      );
      return;
    }

    final file = await ExportService().buildExportFile(tasks, completions);

    if (!context.mounted) return;
    // No success toast here on purpose: the OS share sheet appearing IS
    // the confirmation. We also can't reliably distinguish "user shared
    // it" from "user cancelled the sheet" without adding more complexity
    // than a toast is worth — showing "Exported!" even on cancel would
    // be actively misleading.
    await Share.shareXFiles([XFile(file.path)], text: 'Routine Tracker data export');
  }
}

/// A small looping bell-wiggle in the permission-explainer sheet — draws
/// the eye to what's being requested without being obnoxious about it.
class _WigglingBellIcon extends StatefulWidget {
  final AppPalette palette;
  const _WigglingBellIcon({required this.palette});

  @override
  State<_WigglingBellIcon> createState() => _WigglingBellIconState();
}

class _WigglingBellIconState extends State<_WigglingBellIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    if (!reduceMotion) {
      Future.delayed(const Duration(milliseconds: 200), () {
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
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: widget.palette.purpleTint, shape: BoxShape.circle),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wiggle = _controller.value == 0
              ? 0.0
              : (1 - _controller.value) * 0.35 * (1 - (2 * _controller.value - 1).abs()) * 4;
          return Transform.rotate(angle: wiggle * (_controller.value < 0.5 ? 1 : -1), child: child);
        },
        child: Icon(Icons.notifications, color: widget.palette.purpleAccent, size: 26),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 0.4, color: context.palette.textMuted),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(color: palette.surfaceRaised, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ThemeMode.values.map((mode) {
          final selected = mode == currentMode;
          return Expanded(
            child: Semantics(
              label: '${_label(mode)} theme, ${selected ? 'currently selected' : 'not selected'}',
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? palette.purpleTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    _label(mode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                      color: selected ? palette.purpleText : palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: palette.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Semantics(
            label: '$label, ${value ? 'on' : 'off'}',
            child: Switch(value: value, onChanged: onChanged, activeThumbColor: palette.purpleAccent),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedHint extends StatelessWidget {
  final AppPalette palette;
  const _PermissionDeniedHint({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: palette.amberTint, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.notifications_off, size: 16, color: palette.amberAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Notifications disabled in system settings',
                style: TextStyle(fontSize: 12, color: palette.amberText)),
          ),
          TextButton(
            onPressed: () {
              // TODO: deep-link to OS settings — package choice (e.g.
              // app_settings) intentionally left unverified/unadded here,
              // consistent with this project's policy of not guessing at
              // third-party APIs it can't check against current docs.
            },
            child: Text('Open', style: TextStyle(fontSize: 12, color: palette.amberAccent)),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 17, color: palette.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final AppPalette palette;
  const _VersionRow({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Version', style: TextStyle(fontSize: 12, color: palette.textMuted)),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final text = snapshot.hasData ? snapshot.data!.version : '—';
              return Text(text, style: TextStyle(fontSize: 12, color: palette.textMuted));
            },
          ),
        ],
      ),
    );
  }
}
