// lib/shared/widgets/lt_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../icons/lt_icons.dart';
import '../../core/theme/app_theme.dart';

// ─── LT CARD ──────────────────────────────────────────────────────────────────
class LTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool hasBorder;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LTCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.hasBorder = true,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        color ?? LTColors.surface1,
        borderRadius: borderRadius ?? LTRadius.lg,
        border: hasBorder ? Border.all(color: LTColors.border1) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap!(); },
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}

// ─── LT BUTTON ────────────────────────────────────────────────────────────────
class LTButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final LTIconData? icon;
  final bool isPrimary;
  final bool isSmall;
  final bool isLoading;
  final Color? color;

  const LTButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isPrimary = false,
    this.isSmall = false,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isPrimary ? (color ?? LTColors.cyan) : LTColors.surface3;
    final fg     = isPrimary ? const Color(0xFF050505) : LTColors.text2;
    final border = isPrimary ? BorderSide.none : const BorderSide(color: LTColors.border2);

    return GestureDetector(
      onTap: onTap == null || isLoading ? null : () { HapticFeedback.lightImpact(); onTap!(); },
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: isSmall ? 34 : 44,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 20),
          decoration: BoxDecoration(
            color: bg, borderRadius: LTRadius.sm,
            border: border == BorderSide.none ? null : Border.fromBorderSide(border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.8, color: fg),
              ) else ...[
                if (icon != null) ...[
                  LTIcon(icon!, size: isSmall ? 14 : 16, color: fg, strokeWidth: 2.0),
                  const SizedBox(width: 7),
                ],
                Text(label, style: LTText.body(isSmall ? 13 : 14, weight: FontWeight.w600, color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LT INPUT ─────────────────────────────────────────────────────────────────
class LTInput extends StatelessWidget {
  final String placeholder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final String? label;

  const LTInput({
    super.key,
    required this.placeholder,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onEditingComplete,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: LTText.label),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onEditingComplete: onEditingComplete,
          onChanged: onChanged,
          style: LTText.body(15),
          cursorColor: LTColors.cyan,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: LTText.body(15, color: LTColors.text3),
            filled: true,
            fillColor: LTColors.surface2,
            border: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
            enabledBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
            focusedBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.cyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class LTSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const LTSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title.toUpperCase(), style: LTText.label.copyWith(color: LTColors.text3)),
      const Spacer(),
      if (trailing != null) trailing!
      else if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: LTText.body(13, color: LTColors.cyan)),
        ),
    ],
  );
}

// ─── STAT TILE ────────────────────────────────────────────────────────────────
class LTStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final Widget? icon;

  const LTStatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => LTCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[icon!, const SizedBox(height: 10)],
        Text(value, style: LTText.display(28).copyWith(color: valueColor ?? LTColors.text1)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: LTText.label),
      ],
    ),
  );
}

// ─── PROGRESS ARC (ring) ─────────────────────────────────────────────────────
class LTProgressRing extends StatelessWidget {
  final double value;   // 0.0 – 1.0
  final double size;
  final Color? color;
  final String? label;
  final double strokeWidth;

  const LTProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.color,
    this.label,
    this.strokeWidth = 5,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _RingPainter(value: value, color: color ?? LTColors.cyan, strokeWidth: strokeWidth),
        ),
        if (label != null)
          Text(label!, style: LTText.heading(size * 0.22, weight: FontWeight.w600)),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;
  _RingPainter({required this.value, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background
    canvas.drawArc(rect, -1.5708, 6.2832, false,
      Paint()..color = LTColors.surface3..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    if (value <= 0) return;

    // Progress
    canvas.drawArc(rect, -1.5708, 6.2832 * value.clamp(0, 1), false,
      Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [color, color.withOpacity(0.7)]).createShader(rect));
  }

  @override bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

// ─── PRIORITY BADGE ───────────────────────────────────────────────────────────
class LTPriorityBadge extends StatelessWidget {
  final String priority;
  const LTPriorityBadge(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (priority) {
      'high'   => (LTColors.red,    LTColors.redDim),
      'low'    => (LTColors.green,  LTColors.greenDim),
      _        => (LTColors.gold,   LTColors.goldDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: LTRadius.full),
      child: Text(priority, style: LTText.label.copyWith(color: color, fontSize: 10, letterSpacing: 0.08)),
    );
  }
}

// ─── CHECKBOX ─────────────────────────────────────────────────────────────────
class LTCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  const LTCheckbox({
    super.key,
    required this.checked,
    required this.onTap,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size, height: size,
      decoration: BoxDecoration(
        color:        checked ? (color ?? LTColors.cyan) : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.3),
        border:       Border.all(color: checked ? (color ?? LTColors.cyan) : LTColors.border3, width: 1.5),
      ),
      child: checked
        ? LTIcon(LTIcons.check, size: size * 0.55, color: const Color(0xFF050505), strokeWidth: 2.4)
        : null,
    ),
  );
}

// ─── MOOD PICKER ──────────────────────────────────────────────────────────────
class LTMoodPicker extends StatelessWidget {
  final int? selected; // 0–4
  final ValueChanged<int> onSelect;

  const LTMoodPicker({super.key, this.selected, required this.onSelect});

  static const _labels = ['Terrible', 'Bad', 'Neutral', 'Good', 'Great'];
  static const _lines = [
    // Each mood is a custom drawn face — parameters: mouthCurve (-1 frown, +1 smile)
    -1.0, -0.5, 0.0, 0.5, 1.0,
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: List.generate(5, (i) {
      final isSelected = selected == i;
      final color = LTColors.moodColors[i];
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onSelect(i); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: LTRadius.md,
            border: Border.all(color: isSelected ? color : LTColors.border1, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 32, height: 32,
                child: CustomPaint(
                  painter: _MoodFacePainter(curve: _lines[i], color: isSelected ? color : LTColors.text3),
                ),
              ),
              const SizedBox(height: 6),
              Text(_labels[i], style: LTText.label.copyWith(
                color: isSelected ? color : LTColors.text3, fontSize: 9)),
            ],
          ),
        ),
      );
    }),
  );
}

class _MoodFacePainter extends CustomPainter {
  final double curve;
  final Color color;
  _MoodFacePainter({required this.curve, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width * 0.45;
    // Face circle
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Eyes
    canvas.drawCircle(Offset(cx - r * 0.33, cy - r * 0.15), 1.8, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx + r * 0.33, cy - r * 0.15), 1.8, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    // Mouth
    final mouthPath = Path();
    final mx = cx - r * 0.4; final my = cy + r * 0.2;
    final mw = r * 0.8;
    mouthPath.moveTo(mx, my);
    mouthPath.cubicTo(mx + mw * 0.33, my + curve * r * 0.4, mx + mw * 0.66, my + curve * r * 0.4, mx + mw, my);
    canvas.drawPath(mouthPath, paint);
  }

  @override bool shouldRepaint(_MoodFacePainter old) => old.curve != curve || old.color != color;
}

// ─── BAR CHART SIMPLE ─────────────────────────────────────────────────────────
class LTMiniBarChart extends StatelessWidget {
  final List<double> values;  // normalized 0–1
  final List<String>? labels;
  final Color? barColor;
  final double height;

  const LTMiniBarChart({
    super.key,
    required this.values,
    this.labels,
    this.barColor,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 30),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: (height - 20) * values[i].clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    color: (barColor ?? LTColors.cyan).withOpacity(0.35 + 0.65 * values[i].clamp(0, 1)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
              ),
              if (labels != null && i < labels!.length) ...[
                const SizedBox(height: 4),
                Text(labels![i], style: LTText.label.copyWith(fontSize: 8), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      )),
    ),
  );
}

// ─── HEATMAP GRID ─────────────────────────────────────────────────────────────
class LTHeatmap extends StatelessWidget {
  final Map<DateTime, double> data; // date → 0.0–1.0
  final int weeks;
  final Color? color;

  const LTHeatmap({super.key, required this.data, this.weeks = 12, this.color});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(weeks * 7, (i) {
      final d = now.subtract(Duration(days: weeks * 7 - 1 - i));
      return DateTime(d.year, d.month, d.day);
    });

    return Wrap(
      spacing: 3, runSpacing: 3,
      children: days.map((day) {
        final val = data[day] ?? 0.0;
        final c = color ?? LTColors.cyan;
        return Tooltip(
          message: '${day.month}/${day.day}: ${(val * 100).round()}%',
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: val == 0 ? LTColors.surface3 : c.withOpacity(0.15 + 0.85 * val),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── AVATAR ───────────────────────────────────────────────────────────────────
class LTAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final Color? color;

  const LTAvatar({super.key, this.url, required this.name, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:  color ?? LTColors.cyanDim,
        border: Border.all(color: LTColors.border2),
        image: url != null ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      child: url == null ? Center(
        child: Text(initials, style: LTText.body(size * 0.35, weight: FontWeight.w600, color: LTColors.cyan)),
      ) : null,
    );
  }
}

// ─── SLIDE-UP SHEET ───────────────────────────────────────────────────────────
Future<T?> showLTSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: LTColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: LTColors.border2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: LTColors.border3, borderRadius: LTRadius.full)),
          const SizedBox(height: 4),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────
class LTEmptyState extends StatelessWidget {
  final LTIconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LTEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: LTColors.surface2, borderRadius: LTRadius.xl),
            child: LTIcon(icon, size: 32, color: LTColors.text3),
          ),
          const SizedBox(height: 20),
          Text(title, style: LTText.heading(18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: LTText.body(14, color: LTColors.text3), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            LTButton(label: actionLabel!, onTap: onAction, isPrimary: true),
          ],
        ],
      ),
    ),
  );
}
