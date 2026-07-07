import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'today_screen.dart';
import 'habits_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

/// Bottom-nav shell: Today / Habits / History / Stats (4 tabs — kept at
/// the max per spec). Settings is reached from the avatar icon in the
/// Today header, not a 5th tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _screens = const [
    TodayScreen(),
    HabitsScreen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.purpleAccent,
        foregroundColor: palette.background,
        onPressed: () => context.push('/add-task'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: palette.surface,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Habits'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}
