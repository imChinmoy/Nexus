import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';

enum BrlButtonVariant { primary, secondary, danger, ghost }

class BrlButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BrlButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
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
    this.height,
    this.customGradient,
  });

  @override
  State<BrlButton> createState() => _BrlButtonState();
}

class _BrlButtonState extends State<BrlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnim = _controller;
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final h = widget.height ?? 52.0;
    switch (widget.variant) {
      case BrlButtonVariant.primary:
        return _PrimaryButton(
          label: widget.label,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          leadingIcon: widget.leadingIcon,
          height: h,
          gradient: widget.customGradient ?? AppGradients.primary,
        );
      case BrlButtonVariant.secondary:
        return _SecondaryButton(
          label: widget.label,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          leadingIcon: widget.leadingIcon,
          height: h,
        );
      case BrlButtonVariant.danger:
        return _PrimaryButton(
          label: widget.label,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          leadingIcon: widget.leadingIcon,
          height: h,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4444), Color(0xFFFF006E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case BrlButtonVariant.ghost:
        return _GhostButton(
          label: widget.label,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          leadingIcon: widget.leadingIcon,
          height: h,
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final double height;
  final LinearGradient gradient;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.isFullWidth,
    required this.height,
    required this.gradient,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else ...
            [
              if (leadingIcon != null) ...
                [
                  Icon(leadingIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
              Text(
                label.toUpperCase(),
                style: AppTextStyles.buttonLg.copyWith(color: Colors.white),
              ),
            ]
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final double height;

  const _SecondaryButton({
    required this.label,
    required this.isLoading,
    required this.isFullWidth,
    required this.height,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: AppColors.glassStroke, width: 1.5),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else ...
            [
              if (leadingIcon != null) ...
                [
                  Icon(leadingIcon, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                ],
              Text(
                label.toUpperCase(),
                style: AppTextStyles.buttonMd.copyWith(color: AppColors.primary),
              ),
            ]
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final double height;

  const _GhostButton({
    required this.label,
    required this.isLoading,
    required this.isFullWidth,
    required this.height,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...
            [
              Icon(leadingIcon, color: AppColors.onSurfaceMuted, size: 16),
              const SizedBox(width: 6),
            ],
          Text(
            label,
            style: AppTextStyles.buttonMd.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
