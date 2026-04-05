// lib/shared/icons/lt_icons.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─── ICON PAINTER ─────────────────────────────────────────────────────────────
// All icons are custom-drawn SVG paths — no emoji, no Material icons

class LTIcon extends StatelessWidget {
  final LTIconData icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  const LTIcon(this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IconPainter(
          icon: icon,
          color: color ?? LTColors.text2,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final LTIconData icon;
  final Color color;
  final double strokeWidth;

  _IconPainter({required this.icon, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final s = w / 24; // scale factor (icons designed on 24x24 grid)

    canvas.save();
    canvas.scale(s, s);
    icon.draw(canvas, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.strokeWidth != strokeWidth || old.icon != icon;
}

// ─── ICON DATA ────────────────────────────────────────────────────────────────
abstract class LTIconData {
  void draw(Canvas canvas, Paint paint);
}

// Dashboard / Home — grid of four squares with center dot
class _HomeIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Top-left square
    canvas.drawRRect(RRect.fromLTRBR(3, 3, 10.5, 10.5, const Radius.circular(2.5)), paint);
    // Top-right square
    canvas.drawRRect(RRect.fromLTRBR(13.5, 3, 21, 10.5, const Radius.circular(2.5)), paint);
    // Bottom-left square
    canvas.drawRRect(RRect.fromLTRBR(3, 13.5, 10.5, 21, const Radius.circular(2.5)), paint);
    // Bottom-right square (filled to indicate active)
    canvas.drawRRect(RRect.fromLTRBR(13.5, 13.5, 21, 21, const Radius.circular(2.5)), paint);
  }
}

// Habits — circular repeat arrows
class _HabitsIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Outer arc — top 3/4
    final arcRect = Rect.fromCircle(center: const Offset(12, 12), radius: 8);
    canvas.drawArc(arcRect, -2.4, 5.0, false, paint);
    // Arrow head top right
    final path1 = Path()
      ..moveTo(18.5, 5.5)
      ..lineTo(20.5, 3.2)
      ..moveTo(20.5, 3.2)
      ..lineTo(18.5, 1.5);
    canvas.drawPath(path1, paint);
    // Inner arc — bottom 3/4
    final arcRect2 = Rect.fromCircle(center: const Offset(12, 12), radius: 4.5);
    canvas.drawArc(arcRect2, 0.8, 4.7, false, paint);
    // Arrow head bottom left
    final path2 = Path()
      ..moveTo(5.5, 18.5)
      ..lineTo(3.5, 20.8)
      ..moveTo(3.5, 20.8)
      ..lineTo(5.5, 22.5);
    canvas.drawPath(path2, paint);
  }
}

// Tasks — checkbox with checkmark
class _TasksIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Rounded square
    final path = Path()
      ..moveTo(9, 3)
      ..lineTo(19, 3)
      ..quadraticBezierTo(21, 3, 21, 5)
      ..lineTo(21, 19)
      ..quadraticBezierTo(21, 21, 19, 21)
      ..lineTo(5, 21)
      ..quadraticBezierTo(3, 21, 3, 19)
      ..lineTo(3, 9);
    canvas.drawPath(path, paint);
    // Checkmark
    final check = Path()
      ..moveTo(8, 12.5)
      ..lineTo(11, 15.5)
      ..lineTo(17.5, 8.5);
    canvas.drawPath(check, paint);
    // Corner fold
    final fold = Path()
      ..moveTo(3, 9)
      ..lineTo(9, 9)
      ..lineTo(9, 3);
    canvas.drawPath(fold, paint);
  }
}

// Mood — abstract face lines (no circle)
class _MoodIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Left eye — vertical line
    canvas.drawLine(const Offset(8.5, 8), const Offset(8.5, 10), paint);
    // Right eye — vertical line
    canvas.drawLine(const Offset(15.5, 8), const Offset(15.5, 10), paint);
    // Smile curve
    final smile = Path();
    smile.moveTo(7, 14);
    smile.cubicTo(9, 17, 15, 17, 17, 14);
    canvas.drawPath(smile, paint);
    // Face outline — partial arc, broken
    final arc = Rect.fromCircle(center: const Offset(12, 12), radius: 9);
    canvas.drawArc(arc, 0.4, 5.5, false, paint);
  }
}

// Journal — open book with lines
class _JournalIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Left page
    final left = Path()
      ..moveTo(12, 5)
      ..lineTo(4, 5)
      ..quadraticBezierTo(3, 5, 3, 6)
      ..lineTo(3, 19)
      ..quadraticBezierTo(3, 20, 4, 20)
      ..lineTo(12, 20);
    canvas.drawPath(left, paint);
    // Right page
    final right = Path()
      ..moveTo(12, 5)
      ..lineTo(20, 5)
      ..quadraticBezierTo(21, 5, 21, 6)
      ..lineTo(21, 19)
      ..quadraticBezierTo(21, 20, 20, 20)
      ..lineTo(12, 20);
    canvas.drawPath(right, paint);
    // Spine
    canvas.drawLine(const Offset(12, 5), const Offset(12, 20), paint);
    // Lines on left page
    canvas.drawLine(const Offset(5.5, 9), const Offset(10, 9), paint);
    canvas.drawLine(const Offset(5.5, 12), const Offset(10, 12), paint);
    canvas.drawLine(const Offset(5.5, 15), const Offset(10, 15), paint);
    // Lines on right page
    canvas.drawLine(const Offset(14, 9), const Offset(18.5, 9), paint);
    canvas.drawLine(const Offset(14, 12), const Offset(18.5, 12), paint);
    canvas.drawLine(const Offset(14, 15), const Offset(18.5, 15), paint);
  }
}

// Goals / Flag — geometric flag
class _GoalsIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Flag pole
    canvas.drawLine(const Offset(5, 3), const Offset(5, 21), paint);
    // Flag shape — geometric rhombus flag
    final flag = Path()
      ..moveTo(5, 4.5)
      ..lineTo(20, 8)
      ..lineTo(16, 12)
      ..lineTo(20, 15.5)
      ..lineTo(5, 12.5)
      ..close();
    canvas.drawPath(flag, paint);
    // Small base circle
    canvas.drawCircle(const Offset(5, 21), 1.2, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }
}

// Insights / Analytics — rising bars with sparkle
class _InsightsIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Three bars
    canvas.drawRRect(RRect.fromLTRBR(3, 14, 7, 21, const Radius.circular(1.5)), paint);
    canvas.drawRRect(RRect.fromLTRBR(9.5, 9, 13.5, 21, const Radius.circular(1.5)), paint);
    canvas.drawRRect(RRect.fromLTRBR(16, 5, 20, 21, const Radius.circular(1.5)), paint);
    // Trend line
    final trend = Path()
      ..moveTo(3, 18)
      ..lineTo(7.5, 12)
      ..lineTo(12, 9)
      ..lineTo(20, 4);
    canvas.drawPath(trend, paint);
    // Dot at trend peak
    canvas.drawCircle(const Offset(20, 4), 1.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }
}

// Social / Multiplayer — two figures
class _SocialIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Person 1 head
    canvas.drawCircle(const Offset(9, 7.5), 3, paint);
    // Person 1 body
    final body1 = Path()
      ..moveTo(3.5, 21)
      ..quadraticBezierTo(3.5, 14.5, 9, 14.5)
      ..quadraticBezierTo(14.5, 14.5, 14.5, 21);
    canvas.drawPath(body1, paint);
    // Person 2 head (slightly behind, offset)
    canvas.drawCircle(const Offset(16.5, 7.5), 2.5, paint);
    // Person 2 body (partial, offset right)
    final body2 = Path()
      ..moveTo(13.5, 21)
      ..quadraticBezierTo(13.5, 15.5, 16.5, 15.5)
      ..quadraticBezierTo(20.5, 15.5, 20.5, 21);
    canvas.drawPath(body2, paint);
    // Connection indicator
    canvas.drawLine(const Offset(9, 7.5), const Offset(16.5, 7.5),
      Paint()..color = paint.color..strokeWidth = paint.strokeWidth * 0.6
             ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
    );
  }
}

// Plus / Add
class _PlusIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(12, 4), const Offset(12, 20), paint);
    canvas.drawLine(const Offset(4, 12), const Offset(20, 12), paint);
  }
}

// Checkmark
class _CheckIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(4, 12)
      ..lineTo(9.5, 17.5)
      ..lineTo(20, 6.5);
    canvas.drawPath(path, paint);
  }
}

// Close / X
class _CloseIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(5, 5), const Offset(19, 19), paint);
    canvas.drawLine(const Offset(19, 5), const Offset(5, 19), paint);
  }
}

// Edit / Pencil
class _EditIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(16.5, 3.5)
      ..lineTo(20.5, 7.5)
      ..lineTo(8.5, 19.5)
      ..lineTo(4, 20)
      ..lineTo(4.5, 15.5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(const Offset(14, 6), const Offset(18, 10), paint);
  }
}

// Trash / Delete
class _TrashIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Body
    canvas.drawRRect(RRect.fromLTRBR(5, 7, 19, 21, const Radius.circular(2)), paint);
    // Lid
    canvas.drawLine(const Offset(3, 7), const Offset(21, 7), paint);
    // Handle
    canvas.drawRRect(RRect.fromLTRBR(9, 4, 15, 7, const Radius.circular(1.5)), paint);
    // Lines inside
    canvas.drawLine(const Offset(10, 11), const Offset(10, 17), paint);
    canvas.drawLine(const Offset(14, 11), const Offset(14, 17), paint);
  }
}

// Arrow right / chevron
class _ChevronRightIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(9, 6)
      ..lineTo(15, 12)
      ..lineTo(9, 18);
    canvas.drawPath(path, paint);
  }
}

// Back / Arrow left
class _BackIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(15, 6)
      ..lineTo(9, 12)
      ..lineTo(15, 18);
    canvas.drawPath(path, paint);
  }
}

// Settings / sliders
class _SettingsIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    // Three horizontal lines with circles
    canvas.drawLine(const Offset(3, 6), const Offset(21, 6), paint);
    canvas.drawCircle(const Offset(8, 6), 2.5, Paint()..color = paint.color..style = PaintingStyle.fill);
    canvas.drawLine(const Offset(3, 12), const Offset(21, 12), paint);
    canvas.drawCircle(const Offset(16, 12), 2.5, Paint()..color = paint.color..style = PaintingStyle.fill);
    canvas.drawLine(const Offset(3, 18), const Offset(21, 18), paint);
    canvas.drawCircle(const Offset(10, 18), 2.5, Paint()..color = paint.color..style = PaintingStyle.fill);
  }
}

// Fire / streak
class _FireIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(12, 2)
      ..cubicTo(12, 2, 14, 5, 14, 8)
      ..cubicTo(14, 8, 17, 6, 16, 10)
      ..cubicTo(18, 11, 19, 14, 18, 17)
      ..cubicTo(17, 20, 14.5, 22, 12, 22)
      ..cubicTo(9.5, 22, 7, 20, 6, 17)
      ..cubicTo(5, 14, 6, 11, 8, 10)
      ..cubicTo(7, 6, 10, 8, 10, 8)
      ..cubicTo(10, 5, 12, 2, 12, 2)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    // Inner flame
    final inner = Path()
      ..moveTo(12, 8)
      ..cubicTo(12, 8, 14, 11, 13, 14)
      ..cubicTo(13, 14, 15, 13, 15, 16)
      ..cubicTo(15, 18, 13.5, 19, 12, 19)
      ..cubicTo(10.5, 19, 9, 18, 9, 16)
      ..cubicTo(9, 13, 11, 12, 12, 8)
      ..close();
    canvas.drawPath(inner, paint);
  }
}

// Star
class _StarIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path();
    final cx = 12.0; final cy = 12.0; final r1 = 8.0; final r2 = 3.5;
    for (int i = 0; i < 5; i++) {
      final a1 = (i * 72 - 90) * 3.14159 / 180;
      final a2 = (i * 72 - 90 + 36) * 3.14159 / 180;
      final x1 = cx + r1 * Math.cos(a1); final y1 = cy + r1 * Math.sin(a1);
      final x2 = cx + r2 * Math.cos(a2); final y2 = cy + r2 * Math.sin(a2);
      if (i == 0) path.moveTo(x1, y1); else path.lineTo(x1, y1);
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

// Bell / notification
class _BellIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(6, 10)
      ..quadraticBezierTo(6, 5, 12, 5)
      ..quadraticBezierTo(18, 5, 18, 10)
      ..lineTo(18, 14)
      ..lineTo(20, 16)
      ..lineTo(20, 17)
      ..lineTo(4, 17)
      ..lineTo(4, 16)
      ..lineTo(6, 14)
      ..close();
    canvas.drawPath(path, paint);
    // Clapper
    canvas.drawArc(Rect.fromCenter(center: const Offset(12, 19.5), width: 4, height: 4),
      0, 3.14159, false, paint);
    // Handle
    canvas.drawLine(const Offset(10, 5), const Offset(14, 5),
      Paint()..color = paint.color..strokeWidth = paint.strokeWidth
             ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
}

// User / profile
class _UserIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 8), 4, paint);
    final path = Path()
      ..moveTo(4, 22)
      ..quadraticBezierTo(4, 15, 12, 15)
      ..quadraticBezierTo(20, 15, 20, 22);
    canvas.drawPath(path, paint);
  }
}

// Lock (for auth)
class _LockIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawRRect(RRect.fromLTRBR(5, 11, 19, 21, const Radius.circular(2.5)), paint);
    final path = Path()
      ..moveTo(8, 11)
      ..lineTo(8, 7)
      ..quadraticBezierTo(8, 3, 12, 3)
      ..quadraticBezierTo(16, 3, 16, 7)
      ..lineTo(16, 11);
    canvas.drawPath(path, paint);
    canvas.drawCircle(const Offset(12, 16), 1.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }
}

// Calendar
class _CalendarIcon extends LTIconData {
  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawRRect(RRect.fromLTRBR(3, 5, 21, 21, const Radius.circular(2.5)), paint);
    canvas.drawLine(const Offset(3, 10), const Offset(21, 10), paint);
    canvas.drawLine(const Offset(8, 3), const Offset(8, 7), paint);
    canvas.drawLine(const Offset(16, 3), const Offset(16, 7), paint);
    // Dots for days
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 4; c++) {
        canvas.drawCircle(Offset(6.5 + c * 3.7, 14.5 + r * 3.5), 0.9,
          paint..style = PaintingStyle.fill);
      }
    }
    paint.style = PaintingStyle.stroke;
  }
}

// Math helper
class Math {
  static double cos(double rad) => _cos(rad);
  static double sin(double rad) => _sin(rad);
  static double _cos(double x) {
    var result = 1.0; var term = 1.0;
    for (int i = 1; i <= 10; i++) { term *= -x * x / (2 * i * (2 * i - 1)); result += term; }
    return result;
  }
  static double _sin(double x) {
    var result = x; var term = x;
    for (int i = 1; i <= 10; i++) { term *= -x * x / (2 * i * (2 * i + 1)); result += term; }
    return result;
  }
}

// ─── ICON REGISTRY ────────────────────────────────────────────────────────────
class LTIcons {
  LTIcons._();
  static final home         = _HomeIcon();
  static final habits       = _HabitsIcon();
  static final tasks        = _TasksIcon();
  static final mood         = _MoodIcon();
  static final journal      = _JournalIcon();
  static final goals        = _GoalsIcon();
  static final insights     = _InsightsIcon();
  static final social       = _SocialIcon();
  static final plus         = _PlusIcon();
  static final check        = _CheckIcon();
  static final close        = _CloseIcon();
  static final edit         = _EditIcon();
  static final trash        = _TrashIcon();
  static final chevronRight = _ChevronRightIcon();
  static final back         = _BackIcon();
  static final settings     = _SettingsIcon();
  static final fire         = _FireIcon();
  static final star         = _StarIcon();
  static final bell         = _BellIcon();
  static final user         = _UserIcon();
  static final lock         = _LockIcon();
  static final calendar     = _CalendarIcon();
}
