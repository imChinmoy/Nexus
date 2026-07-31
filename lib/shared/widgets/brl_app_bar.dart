import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BrlAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final Color? accentColor;
  final PreferredSizeWidget? bottom;

  const BrlAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.leading,
    this.accentColor,
    this.bottom,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          backgroundColor: const Color(0x1A0A0F1E),
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                accentColor ?? AppColors.primary,
                (accentColor ?? AppColors.secondary),
              ],
            ).createShader(bounds),
            child: Text(
              title,
              style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
            ),
          ),
          leading: showBack
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : leading,
          actions: actions,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.glassStroke,
            ),
          ),
        ),
      ),
    );
  }
}
