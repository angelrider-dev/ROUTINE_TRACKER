import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../screens/add_task_screen.dart';
import '../screens/app_shell.dart';
import '../screens/settings_screen.dart';

/// HONEST RISK FLAG: this app only has two navigation actions (open
/// Add/Edit Task, open Settings), which is why go_router is worth wiring
/// properly here rather than leaving it as an unused pubspec.yaml entry —
/// the surface area to get wrong is small. The one part I'm least certain
/// of without doc access is `CustomTransitionPage`'s exact constructor
/// shape for the slide-up-and-fade transition below; the rest (basic
/// `GoRoute`/nested routes/`context.push`) has been stable across
/// go_router's major versions for a long time.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShell(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'add-task',
          pageBuilder: (context, state) {
            final existingTask = state.extra as RoutineTask?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: AddTaskScreen(existingTask: existingTask),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);
