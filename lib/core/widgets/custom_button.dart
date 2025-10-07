import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isPrimary = true,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonStyle = ElevatedButton.styleFrom(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 28.w, vertical: 18.h),
      backgroundColor: isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      foregroundColor: isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ElevatedButton(
      style: buttonStyle,
      onPressed: onPressed,
      child: icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                SizedBox(width: 12.w),
                Text(label),
              ],
            ),
    );
  }
}
