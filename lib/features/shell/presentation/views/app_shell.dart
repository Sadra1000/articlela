import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../shell/presentation/widgets/app_title_bar.dart';
import '../../../../app/theme/app_colors.dart';

typedef TitleBuilder = String Function(AppLocalizations l10n);

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    this.preset,
    this.titleBuilder,
  });

  final Widget child;
  final GradientPreset? preset;
  final TitleBuilder? titleBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    final gradient = AppColors.gradient(preset ?? _resolvePreset(routeName));
    final title = titleBuilder != null ? titleBuilder!(l10n) : l10n.appTitle;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AppTitleBar(
            title: title,
            showBack: canPop,
            onBack: canPop ? () => Navigator.of(context).maybePop() : null,
          ),
          Expanded(
            child: GradientScaffold(
              gradient: gradient,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Directionality(
                  key: ValueKey<String>(l10n.locale.languageCode + routeName),
                  textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  GradientPreset _resolvePreset(String route) {
    switch (route) {
      case '/home':
        return GradientPreset.home;
      case '/about':
        return GradientPreset.about;
      case '/settings':
        return GradientPreset.settings;
      case '/keywords':
        return GradientPreset.keyword;
      case '/results':
        return GradientPreset.results;
      default:
        return GradientPreset.home;
    }
  }
}
