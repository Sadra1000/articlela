import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.gradient,
    required this.child,
    this.overlay,
    this.bottomBar,
    
  });

  final Gradient gradient;
  final Widget child;
  final Widget? overlay;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: SafeArea(
                bottom: bottomBar == null,
                child: child,
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
