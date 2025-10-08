import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_state.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/navigation/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../presentation/viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _elsevierController;
  late final TextEditingController _mailtoController;
  bool _controllersSeeded = false;

  @override
  void initState() {
    super.initState();
    _elsevierController = TextEditingController();
    _mailtoController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<OnboardingViewModel>();
    viewModel.initialize().then((_) {
      if (!mounted || _controllersSeeded) return;
      _seedControllers(viewModel);
    });
  }

  void _seedControllers(OnboardingViewModel viewModel) {
    _elsevierController.text = viewModel.elsevierKey;
    _mailtoController.text = viewModel.crossrefMailto;
    _controllersSeeded = true;
  }

  @override
  void dispose() {
    _elsevierController.dispose();
    _mailtoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final isWide = MediaQuery.of(context).size.width > 880;

    if (!viewModel.isLoading && !_controllersSeeded) {
      _seedControllers(viewModel);
    }

    final Widget content = viewModel.isLoading
        ? const Center(child: LoadingIndicator())
        : viewModel.currentStep == 0
            ? _LanguageStep(
                selectedLocale: viewModel.selectedLocale,
                onLocaleSelected: viewModel.changeLocale,
                onContinue: () => _handleLanguageContinue(viewModel),
                isSaving: viewModel.isSaving,
              )
            : _KeysStep(
                elsevierController: _elsevierController,
                mailtoController: _mailtoController,
                scopusEnabled: viewModel.scopusEnabled,
                canContinue: viewModel.canContinueStep2 && !viewModel.isSaving,
                isSaving: viewModel.isSaving,
                onToggleScopus: viewModel.toggleScopus,
                onElsevierChanged: viewModel.updateElsevierKey,
                onMailtoChanged: viewModel.updateCrossrefMailto,
                onFinish: () => _handleFinish(viewModel),
              );

    final lottieAsset =
        viewModel.currentStep == 0 ? 'assets/lottie/onboarding.json' : 'assets/lottie/onboarding.json';

    if (isWide) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: SingleChildScrollView(child: content),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(right: 32.w),
              child: Lottie.asset(lottieAsset, repeat: true, fit: BoxFit.contain),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        children: [
          SizedBox(height: 220.h, child: Lottie.asset(lottieAsset, repeat: true)),
          SizedBox(height: 24.h),
          content,
        ],
      ),
    );
  }

  Future<void> _handleLanguageContinue(OnboardingViewModel viewModel) async {
    final appState = context.read<AppStateNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    await viewModel.completeLanguageStep();
    if (!mounted) return;
    appState.updateLocale(viewModel.selectedLocale);
    messenger.showSnackBar(SnackBar(content: Text(context.l10n.snackbarLanguageSaved)));
  }

  Future<void> _handleFinish(OnboardingViewModel viewModel) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await viewModel.finishOnboarding();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(context.l10n.onboardingCompleteMessage)));
    navigator.pushReplacementNamed(AppRouter.home);
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.selectedLocale,
    required this.onLocaleSelected,
    required this.onContinue,
    required this.isSaving,
  });

  final Locale selectedLocale;
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
        SizedBox(height: 16.h),
        Text(
          l10n.onboardingDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
              selected: selectedLocale.languageCode == 'en',
              onTap: () => onLocaleSelected(const Locale('en')),
            ),
            _LanguageChip(
              label: l10n.languagePersian,
              selected: selectedLocale.languageCode == 'fa',
              onTap: () => onLocaleSelected(const Locale('fa')),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        CustomButton(
          label: l10n.onboardingContinue,
          onPressed: isSaving ? null : onContinue,
          icon: isSaving ? const LoadingIndicator(size: 22) : null,
        ),
      ],
    );
  }
}

class _KeysStep extends StatelessWidget {
  const _KeysStep({
    required this.elsevierController,
    required this.mailtoController,
    required this.scopusEnabled,
    required this.canContinue,
    required this.isSaving,
    required this.onToggleScopus,
    required this.onElsevierChanged,
    required this.onMailtoChanged,
    required this.onFinish,
  });

  final TextEditingController elsevierController;
  final TextEditingController mailtoController;
  final bool scopusEnabled;
  final bool canContinue;
  final bool isSaving;
  final ValueChanged<bool> onToggleScopus;
  final ValueChanged<String> onElsevierChanged;
  final ValueChanged<String> onMailtoChanged;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingKeysTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        SizedBox(height: 12.h),
        Text(
          l10n.onboardingKeysDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
        SizedBox(height: 24.h),
        SwitchListTile.adaptive(
          value: scopusEnabled,
          onChanged: (value) {
            onToggleScopus(value);
            if (!value) {
              elsevierController.clear();
              onElsevierChanged('');
            }
          },
          title: Text(
            l10n.onboardingScopusToggle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          subtitle: Text(
            l10n.onboardingScopusHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: elsevierController,
          onChanged: onElsevierChanged,
          enabled: scopusEnabled,
          decoration: InputDecoration(
            labelText: l10n.onboardingElsevierLabel,
            hintText: l10n.onboardingElsevierHint,
            helperText:
                scopusEnabled ? l10n.onboardingElsevierHelper : l10n.onboardingScopusDisabledHelper,
          ),
        ),
        SizedBox(height: 20.h),
        TextField(
          controller: mailtoController,
          onChanged: onMailtoChanged,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.onboardingCrossrefLabel,
            hintText: l10n.settingsCrossrefMailtoHint,
          ),
        ),
        SizedBox(height: 32.h),
        CustomButton(
          label: l10n.onboardingFinish,
          onPressed: canContinue ? onFinish : null,
          icon: isSaving ? const LoadingIndicator(size: 22) : null,
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
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color:
              selected ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
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
