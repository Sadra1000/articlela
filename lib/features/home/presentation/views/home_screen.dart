import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/navigation/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final homeVm = context.watch<HomeViewModel>();

    return Container(
      padding:EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(
            l10n.homeTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.homeSubtitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: _HomeActions(l10n: l10n)),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Lottie.asset(
                            'assets/lottie/home.json',
                            // width: 360.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: Lottie.asset('assets/lottie/home.json')),
                    SizedBox(height: 24.h),
                    _HomeActions(l10n: l10n),
                    if (homeVm.version.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      Text(
                        l10n.versionLabel(homeVm.version),
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          label: l10n.homeStart,
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRouter.keywordConfig),
        ),
        SizedBox(height: 16.h),
        CustomButton(
          label: l10n.homePdfReader,
          isPrimary: false,
          onPressed: () => Navigator.of(context).pushNamed(AppRouter.pdfReader),
        ),
        SizedBox(height: 16.h),
        CustomButton(
          label: l10n.homeAbout,
          isPrimary: false,
          onPressed: () => Navigator.of(context).pushNamed(AppRouter.about),
        ),
        SizedBox(height: 16.h),
        CustomButton(
          label: l10n.homeSettings,
          isPrimary: false,
          onPressed: () => Navigator.of(context).pushNamed(AppRouter.settings),
        ),
      ],
    );
  }
}
