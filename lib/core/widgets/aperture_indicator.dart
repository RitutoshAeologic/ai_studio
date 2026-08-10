import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../constants/app_colors.dart';

/// Signature animation widget — radial iris/aperture blade ring.
/// Responsive layout using ScreenUtil and AppColors per ui_ux.md.
enum ApertureState { opening, open, closing }

class ApertureIndicator extends StatefulWidget {
  const ApertureIndicator({
    super.key,
    this.size,
    this.color = AppColors.primaryAction,
    this.bladeCount = 8,
    this.state = ApertureState.opening,
    this.onClosed,
  });

  final double? size;
  final Color color;
  final int bladeCount;
  final ApertureState state;

  /// Callback fired when a [ApertureState.closing] animation completes.
  final VoidCallback? onClosed;

  @override
  State<ApertureIndicator> createState() => _ApertureIndicatorState();
}

class _ApertureIndicatorState extends State<ApertureIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _openClose;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildAnimations();
    _start();
  }

  @override
  void didUpdateWidget(ApertureIndicator old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _buildAnimations();
      _start();
    }
  }

  void _buildAnimations() {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _openClose = Tween<double>(
      begin: widget.state == ApertureState.opening ? 0.0 : 1.0,
      end: widget.state == ApertureState.closing ? 0.0 : 1.0,
    ).animate(curve);

    _rotate = Tween<double>(
      begin: 0,
      end: widget.state == ApertureState.opening ? 1 : -1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  void _start() {
    _controller.reset();
    if (widget.state == ApertureState.open) {
      _controller.repeat();
    } else if (widget.state == ApertureState.closing) {
      _controller.forward().whenComplete(() => widget.onClosed?.call());
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.size ?? 56.r;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(effectiveSize, effectiveSize),
        painter: _AperturePainter(
          openAmount: widget.state == ApertureState.open
              ? 1.0
              : _openClose.value,
          rotation: widget.state == ApertureState.open
              ? _rotate.value * 2 * math.pi
              : _rotate.value * math.pi * 0.25,
          color: widget.color,
          bladeCount: widget.bladeCount,
        ),
      ),
    );
  }
}

class _AperturePainter extends CustomPainter {
  const _AperturePainter({
    required this.openAmount,
    required this.rotation,
    required this.color,
    required this.bladeCount,
  });

  final double openAmount;
  final double rotation;
  final Color color;
  final int bladeCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withAlpha(((0.15 + 0.85 * openAmount) * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final innerRadius = radius * (1.0 - 0.6 * openAmount);

    for (int i = 0; i < bladeCount; i++) {
      final angle = rotation + (i * 2 * math.pi / bladeCount);
      final startAngle = angle - 0.4 * (1.0 - openAmount + 0.1);
      final sweepAngle = (math.pi * 1.4) * openAmount + 0.1;

      final bladePath = Path();
      bladePath.addArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
      );
      bladePath.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      bladePath.close();

      final fillPaint = Paint()
        ..color = color.withAlpha(((0.08 + 0.12 * openAmount) * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.drawPath(bladePath, fillPaint);
      canvas.drawPath(bladePath, paint);
    }

    final dotPaint = Paint()
      ..color = color.withAlpha(((0.4 + 0.6 * openAmount) * 255).toInt())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3 * openAmount + 1, dotPaint);
  }

  @override
  bool shouldRepaint(_AperturePainter old) =>
      old.openAmount != openAmount ||
      old.rotation != rotation ||
      old.color != color;
}
