import 'package:flutter/material.dart';

// Brand colors used in the whole app
const Color accentColor = Color(0xFF0F766E);
const Color accentDark = Color(0xFF0B5550);
const Color accentBright = Color(0xFF14B8A6);
const Color lightAccent = Color(0xFFE6F4F1);

// One color per category (used for icons and charts)
const Map<String, Color> categoryColors = {
  'Food': Color(0xFFF97316),
  'Transport': Color(0xFF3B82F6),
  'Shopping': Color(0xFFEC4899),
  'Bills': Color(0xFF8B5CF6),
  'Health': Color(0xFFEF4444),
  'Entertainment': Color(0xFFEAB308),
  'Other': Color(0xFF64748B),
};

Color categoryColor(String category) {
  return categoryColors[category] ?? const Color(0xFF64748B);
}

// Gradient used on the main cards and the login header
const LinearGradient brandGradient = LinearGradient(
  colors: [accentDark, accentColor, accentBright],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Light and dark mode share the same shapes, only colors change
ThemeData buildTheme(Brightness brightness) {
  bool dark = brightness == Brightness.dark;
  ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: brightness,
  );
  Color background = dark ? const Color(0xFF0F1417) : const Color(0xFFF5F7F8);
  Color surface = dark ? const Color(0xFF1A2125) : Colors.white;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(surface: surface),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: dark ? Colors.white : const Color(0xFF111827),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: dark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentColor, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: dark ? accentColor.withValues(alpha: 0.35) : lightAccent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: dark ? accentColor.withValues(alpha: 0.35) : lightAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
