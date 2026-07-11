import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════
  // ADMIN COLORS - Deep Blue Professional
  // ═══════════════════════════════════════
  static const Color adminPrimary = Color(0xFF1A237E);
  static const Color adminPrimaryLight = Color(0xFF3949AB);
  static const Color adminPrimaryDark = Color(0xFF0D1257);
  static const Color adminAccent = Color(0xFF00BCD4);
  static const Color adminSecondary = Color(0xFF283593);

  // ═══════════════════════════════════════
  // TRADER COLORS - Orange Energetic
  // ═══════════════════════════════════════
  static const Color traderPrimary = Color(0xFFE65100);
  static const Color traderPrimaryLight = Color(0xFFFF6D00);
  static const Color traderPrimaryDark = Color(0xFFBF360C);
  static const Color traderAccent = Color(0xFFFFAB40);
  static const Color traderSecondary = Color(0xFFEF6C00);

  // ═══════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════
  static const Color pending = Color(0xFFFF6B35);
  static const Color pendingLight = Color(0xFFFFF3EE);
  static const Color approved = Color(0xFF2E7D32);
  static const Color approvedLight = Color(0xFFE8F5E9);
  static const Color rejected = Color(0xFFC62828);
  static const Color rejectedLight = Color(0xFFFFEBEE);
  static const Color counter = Color(0xFFF57F17);
  static const Color counterLight = Color(0xFFFFFDE7);

  // ═══════════════════════════════════════
  // NEUTRAL COLORS
  // ═══════════════════════════════════════
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFD1D5DB);

  // ═══════════════════════════════════════
  // BORDER & DIVIDER
  // ═══════════════════════════════════════
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ═══════════════════════════════════════
  // GRADIENT
  // ═══════════════════════════════════════
  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
  );

  static const LinearGradient traderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
}