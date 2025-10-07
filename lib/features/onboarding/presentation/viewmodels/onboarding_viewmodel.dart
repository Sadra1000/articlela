import 'package:flutter/material.dart';

import '../../domain/usecases/set_language_usecase.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._setLanguageUseCase) {
    _selectedLocale = _setLanguageUseCase.resolveInitialLocale();
  }

  final SetLanguageUseCase _setLanguageUseCase;

  Locale _selectedLocale = const Locale('en');
  bool _isSaving = false;

  Locale get selectedLocale => _selectedLocale;
  bool get isSaving => _isSaving;

  void changeLocale(Locale locale) {
    if (_selectedLocale == locale) {
      return;
    }
    _selectedLocale = locale;
    notifyListeners();
  }

  Future<void> persistSelection() async {
    _isSaving = true;
    notifyListeners();
    await _setLanguageUseCase.call(_selectedLocale);
    _isSaving = false;
    notifyListeners();
  }
}
