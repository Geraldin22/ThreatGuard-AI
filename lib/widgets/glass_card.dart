import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lightweight frosted glass floating card optimized for 60-120 FPS performance across all devices.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.card,
    this.glow,
    this.onTap,
    this.blur = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;
  final VoidCallback? onTap;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
          if (glow != null)
            BoxShadow(
              color: glow!.withAlpha(50),
              blurRadius: 24,
              spreadRadius: -4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.white(0.12), AppColors.white(0.04)],
            ),
            border: Border.all(color: AppColors.white(0.14)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: r,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

