import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Loaded BEFORE runApp() so the correct theme is already known on the
  // very first frame — avoids a flash of the wrong theme on cold start.
  WidgetsFlutterBinding.ensureInitialized();
  final initialMode = await loadInitialThemeMode();

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => ThemeModeNotifier(initialMode)),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const RoutineTrackerApp(),
    ),
  );
}

class RoutineTrackerApp extends ConsumerWidget {
  const RoutineTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Routine Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      // AnimatedTheme cross-fades the resolved theme over 300ms whenever
      // it changes — MaterialApp's own theme/darkTheme/themeMode switch
      // is instant under the hood, this wrapper is what makes it visually
      // ease from one palette to the other (see Settings screen).
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final resolvedDark = mode == ThemeMode.system
            ? platformBrightness == Brightness.dark
            : mode == ThemeMode.dark;
        final targetTheme = resolvedDark ? buildDarkTheme() : buildLightTheme();

        return AnimatedTheme(
          data: targetTheme,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: child!,
        );
      },
      routerConfig: appRouter,
    );
  }
}
