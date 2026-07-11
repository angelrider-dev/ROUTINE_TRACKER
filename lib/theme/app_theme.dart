import 'package:flutter/material.dart';
import '../models/task.dart' show TaskCategory;

/// All app colors live on a ThemeExtension (AppPalette) rather than as
/// static constants, so light/dark mode is a real theme swap — not two
/// copy-pasted widget trees. `lerp()` is fully implemented (every field
/// interpolated) specifically so AnimatedTheme can cross-fade smoothly
/// between the two palettes on the Settings screen, instead of hard-cutting.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background, surface, surfaceRaised, border, borderSubtle;
  final Color textPrimary, textSecondary, textMuted;

  final Color purpleTint, purpleAccent, purpleText, ringTrack;
  final Color greenTint, greenAccent, greenText;
  final Color blueTint, blueAccent, blueText;
  final Color coralTint, coralAccent, coralText;
  final Color amberTint, amberAccent, amberText;
  final Color pinkTint, pinkAccent, pinkText;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.purpleTint,
    required this.purpleAccent,
    required this.purpleText,
    required this.ringTrack,
    required this.greenTint,
    required this.greenAccent,
    required this.greenText,
    required this.blueTint,
    required this.blueAccent,
    required this.blueText,
    required this.coralTint,
    required this.coralAccent,
    required this.coralText,
    required this.amberTint,
    required this.amberAccent,
    required this.amberText,
    required this.pinkTint,
    required this.pinkAccent,
    required this.pinkText,
  });

  static const dark = AppPalette(
    background: Color(0xFF0D0D0F),
    surface: Color(0xFF1A1A1D),
    surfaceRaised: Color(0xFF232326),
    border: Color(0xFF2F2F33),
    borderSubtle: Color(0xFF262629),
    textPrimary: Color(0xFFF2F2F3),
    textSecondary: Color(0xFFB3B3B8),
    textMuted: Color(0xFF7A7A80),
    purpleTint: Color(0xFF221F38),
    purpleAccent: Color(0xFF9D8EF0),
    purpleText: Color(0xFFD9D3FB),
    ringTrack: Color(0xFF3A325E),
    greenTint: Color(0xFF16241A),
    greenAccent: Color(0xFF7FBF5C),
    greenText: Color(0xFFBFE0A8),
    blueTint: Color(0xFF131F2E),
    blueAccent: Color(0xFF4F8FD9),
    blueText: Color(0xFFBCDCFB),
    coralTint: Color(0xFF2C1912),
    coralAccent: Color(0xFFE0805A),
    coralText: Color(0xFFF5C4AE),
    amberTint: Color(0xFF2B2210),
    amberAccent: Color(0xFFD9A13D),
    amberText: Color(0xFFF0D2A0),
    pinkTint: Color(0xFF2A1521),
    pinkAccent: Color(0xFFD9648F),
    pinkText: Color(0xFFF0B7CF),
  );

  // NOTE: `ringTrack` for light mode is a design judgment call, not from
  // an explicit spec value — a pale lavender-grey that sits between
  // purpleTint and purpleAccent, mirroring the dark theme's relationship.
  static const light = AppPalette(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF2F2F3),
    border: Color(0xFFE4E4E7),
    borderSubtle: Color(0xFFECECEE),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFFA1A1AA),
    purpleTint: Color(0xFFEEEDFE),
    purpleAccent: Color(0xFF534AB7),
    purpleText: Color(0xFF3C3489),
    ringTrack: Color(0xFFD9D3EF),
    greenTint: Color(0xFFEAF3DE),
    greenAccent: Color(0xFF639922),
    greenText: Color(0xFF27500A),
    blueTint: Color(0xFFE6F1FB),
    blueAccent: Color(0xFF378ADD),
    blueText: Color(0xFF0C447C),
    coralTint: Color(0xFFFAECE7),
    coralAccent: Color(0xFFD96B45),
    coralText: Color(0xFF712B13),
    amberTint: Color(0xFFFAEEDA),
    amberAccent: Color(0xFFB77E10),
    amberText: Color(0xFF633806),
    pinkTint: Color(0xFFFBEAF0),
    pinkAccent: Color(0xFFB23A64),
    pinkText: Color(0xFF72243E),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      purpleTint: c(purpleTint, other.purpleTint),
      purpleAccent: c(purpleAccent, other.purpleAccent),
      purpleText: c(purpleText, other.purpleText),
      ringTrack: c(ringTrack, other.ringTrack),
      greenTint: c(greenTint, other.greenTint),
      greenAccent: c(greenAccent, other.greenAccent),
      greenText: c(greenText, other.greenText),
      blueTint: c(blueTint, other.blueTint),
      blueAccent: c(blueAccent, other.blueAccent),
      blueText: c(blueText, other.blueText),
      coralTint: c(coralTint, other.coralTint),
      coralAccent: c(coralAccent, other.coralAccent),
      coralText: c(coralText, other.coralText),
      amberTint: c(amberTint, other.amberTint),
      amberAccent: c(amberAccent, other.amberAccent),
      amberText: c(amberText, other.amberText),
      pinkTint: c(pinkTint, other.pinkTint),
      pinkAccent: c(pinkAccent, other.pinkAccent),
      pinkText: c(pinkText, other.pinkText),
    );
  }
}

/// Shortcut so widgets can write `context.palette.purpleTint` instead of
/// the verbose `Theme.of(context).extension<AppPalette>()!` every time.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

extension TaskCategoryStyle on TaskCategory {
  Color tint(AppPalette p) {
    switch (this) {
      case TaskCategory.fitness:
        return p.greenTint;
      case TaskCategory.work:
        return p.blueTint;
      case TaskCategory.mind:
        return p.coralTint;
      case TaskCategory.learning:
        return p.amberTint;
      case TaskCategory.reflect:
        return p.pinkTint;
    }
  }

  Color accent(AppPalette p) {
    switch (this) {
      case TaskCategory.fitness:
        return p.greenAccent;
      case TaskCategory.work:
        return p.blueAccent;
      case TaskCategory.mind:
        return p.coralAccent;
      case TaskCategory.learning:
        return p.amberAccent;
      case TaskCategory.reflect:
        return p.pinkAccent;
    }
  }

  Color text(AppPalette p) {
    switch (this) {
      case TaskCategory.fitness:
        return p.greenText;
      case TaskCategory.work:
        return p.blueText;
      case TaskCategory.mind:
        return p.coralText;
      case TaskCategory.learning:
        return p.amberText;
      case TaskCategory.reflect:
        return p.pinkText;
    }
  }

  String get label {
    switch (this) {
      case TaskCategory.fitness:
        return 'Fitness';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.mind:
        return 'Mind';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.reflect:
        return 'Reflect';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.fitness:
        return Icons.directions_run;
      case TaskCategory.work:
        return Icons.people;
      case TaskCategory.mind:
        return Icons.fitness_center;
      case TaskCategory.learning:
        return Icons.menu_book;
      case TaskCategory.reflect:
        return Icons.create;
    }
  }
}

ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
    colorScheme: base.colorScheme.copyWith(
      primary: palette.purpleAccent,
      surface: palette.surface,
      onSurface: palette.textPrimary,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: palette.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: palette.border, width: 0.5),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.borderSubtle, thickness: 0.5),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: palette.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: 11, color: palette.textMuted),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.purpleAccent : null,
      ),
    ),
  );
}

ThemeData buildDarkTheme() => _buildTheme(AppPalette.dark, Brightness.dark);
ThemeData buildLightTheme() => _buildTheme(AppPalette.light, Brightness.light);
