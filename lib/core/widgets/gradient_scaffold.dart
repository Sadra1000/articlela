import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.gradient,
    required this.child,
    this.overlay,
    this.bottomBar,
    this.padding,
  });

  final Gradient gradient;
  final Widget child;
  final Widget? overlay;
  final Widget? bottomBar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: padding ?? EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                child: SafeArea(
                  bottom: bottomBar == null,
                  child: child,
                ),
              ),
            ),
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
          if (bottomBar != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: bottomBar!,
              ),
            ),
        ],
      ),
    );
  }
}
