import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../app/l10n/app_localizations.dart';

class AppTitleBar extends StatefulWidget {
  const AppTitleBar({
    super.key,
    required this.title,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initState();
  }

  Future<void> _initState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return  GestureDetector(
       behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),          // ← شروع درگ پنجره
      onDoubleTap: () async {                                     // ← دو بار کلیک = maximize/restore
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          height: 56.h,
          child: Row(
            children: [
              if (widget.showBack)
                _TitleButton(
                  tooltip: l10n.back,
                  icon: Icons.arrow_back,
                  onPressed: widget.onBack,
                ),
              SizedBox(width: widget.showBack ? 12.w : 0),
              SvgPicture.asset(
                'assets/svg/logo.svg',
                width: 28.w,
                height: 28.w,
              ),
              SizedBox(width: 12.w),
              Flexible(
                child: 
                   Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              
              SizedBox(width: 16.w),
              _TitleButton(
                tooltip: 'Minimize',
                icon: Icons.remove,
                onPressed: windowManager.minimize,
              ),
              _TitleButton(
                tooltip: _isMaximized ? 'Restore' : 'Maximize',
                icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                onPressed: () async {
                  final maximized = await windowManager.isMaximized();
                  if (maximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _TitleButton(
                tooltip: 'Close',
                icon: Icons.close,
                onPressed: windowManager.close,
                isDestructive: true,
              ),
              // Expanded(child: MoveWindow())
            ],
          )),
    );
      
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48.w,
      height: 40.h,
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18.w),
          color: isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant,
          splashRadius: 20,
        ),
      ),
    );
  }
}
