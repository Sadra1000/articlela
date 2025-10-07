import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_state.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/navigation/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final locale = viewModel.selectedLocale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final content = _OnboardingContent(
          locale: locale,
          onLocaleSelected: viewModel.changeLocale,
          onContinue: () => _onContinue(context, viewModel),
          isSaving: viewModel.isSaving,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  child: content,
                ),
              ),
              // Expanded(
              //   child: Padding(
              //     padding: EdgeInsets.only(right: 24.w),
              //     child: Lottie.asset(
              //       'assets/lottie/onboarding.json',
              //       repeat: true,
              //       fit: BoxFit.contain,
              //     ),
              //   ),
              // ),
            ],
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              children: [
                SizedBox(
                  height: 220.h,
                  child: Lottie.asset('assets/lottie/onboarding.json', repeat: true),
                ),
                SizedBox(height: 24.h),
                content,
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onContinue(BuildContext context, OnboardingViewModel viewModel) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await viewModel.persistSelection();
    if (!context.mounted) return;

    context.read<AppStateNotifier>().updateLocale(viewModel.selectedLocale);
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarLanguageSaved)),
    );

    navigator.pushReplacementNamed(AppRouter.home);
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    required this.locale,
    required this.onLocaleSelected,
    required this.onContinue,
    required this.isSaving,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleSelected;
  final VoidCallback onContinue;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appTagline,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        SizedBox(height: 12.h),
        Text(
          l10n.onboardingHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        ),
        SizedBox(height: 12.h),
        Text(
          l10n.onboardingDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
        ),
        SizedBox(height: 24.h),
        Text(
          l10n.onboardingSelectLanguage,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 16.w,
          runSpacing: 12.h,
          children: [
            _LanguageChip(
              label: l10n.languageEnglish,
              selected: locale.languageCode == 'en',
              onTap: () => onLocaleSelected(const Locale('en')),
            ),
            _LanguageChip(
              label: l10n.languagePersian,
              selected: locale.languageCode == 'fa',
              onTap: () => onLocaleSelected(const Locale('fa')),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        CustomButton(
          label: l10n.onboardingContinue,
          onPressed: isSaving ? null : onContinue,
          icon: isSaving ? const LoadingIndicator(size: 24) : null,
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: selected ? Colors.white : Colors.white38,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
