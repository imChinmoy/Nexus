import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BrlTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isPassword;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final int? maxLines;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Color? glowColor;

  const BrlTextField({
    super.key,
    required this.label,
    this.hint,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isPassword = false,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.glowColor,
  });

  @override
  State<BrlTextField> createState() => _BrlTextFieldState();
}

class _BrlTextFieldState extends State<BrlTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final fillColor = isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondaryBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscure,
      enabled: widget.enabled,
      maxLines: _obscure ? 1 : widget.maxLines,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: AppTextStyles.bodyMd.copyWith(color: textPrimary),
      cursorColor: accent,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText ?? widget.hint,
        prefixIcon: widget.prefix,
        suffixIcon: (widget.isPassword || widget.obscureText)
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: textSecondary,
                  size: 20,
                ),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffix,
        filled: true,
        fillColor: fillColor,
        labelStyle: AppTextStyles.bodyMd.copyWith(color: textSecondary),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: textTertiary),
        errorStyle: AppTextStyles.caption.copyWith(color: errorColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0x0AFFFFFF) : const Color(0x05000000),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
