import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum BrlButtonVariant { primary, secondary, danger, ghost }

class BrlButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BrlButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? icon;
  final double? height;
  final LinearGradient? customGradient;

  const BrlButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BrlButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.icon,
    this.height,
    this.customGradient,
  });

  @override
  State<BrlButton> createState() => _BrlButtonState();
}

class _BrlButtonState extends State<BrlButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
    );
    _scaleAnimation = _controller;
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final h = widget.height ?? 48.0;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case BrlButtonVariant.primary:
        bg = isDark ? AppColors.darkAccent : AppColors.lightAccent;
        fg = Colors.white;
        break;
      case BrlButtonVariant.secondary:
        bg = isDark ? const Color(0x262997FF) : const Color(0x140071E3);
        fg = isDark ? AppColors.darkAccent : AppColors.lightAccent;
        break;
      case BrlButtonVariant.danger:
        bg = isDark ? AppColors.errorDark : AppColors.error;
        fg = Colors.white;
        break;
      case BrlButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
    }

    if (!isEnabled && widget.variant != BrlButtonVariant.ghost) {
      bg = isDark ? const Color(0xFF2C2C30) : const Color(0xFFE5E5EA);
      fg = isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : null,
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.customGradient == null ? bg : null,
            gradient: widget.customGradient,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              else ...[
                if ((widget.icon ?? widget.leadingIcon) != null) ...[
                  Icon(widget.icon ?? widget.leadingIcon, color: fg, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.buttonMd.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
