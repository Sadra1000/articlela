import 'package:flutter/material.dart';

import '../../../../core/data/services/key_store.dart';
import '../../domain/usecases/set_language_usecase.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._setLanguageUseCase, this._keyStore) {
    _selectedLocale = _setLanguageUseCase.resolveInitialLocale();
  }

  final SetLanguageUseCase _setLanguageUseCase;
  final KeyStore _keyStore;

  Locale _selectedLocale = const Locale('en');
  String _elsevierKey = '';
  String _crossrefMailto = '';
  bool _scopusEnabled = false;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _initialized = false;
  int _currentStep = 0;

  Locale get selectedLocale => _selectedLocale;
  String get elsevierKey => _elsevierKey;
  String get crossrefMailto => _crossrefMailto;
  bool get scopusEnabled => _scopusEnabled;
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;
  int get currentStep => _currentStep;

  bool get canContinueStep2 => !_scopusEnabled || _elsevierKey.trim().isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) return;

    final savedKey = await _keyStore.getElsevierKey();
    final savedMail = await _keyStore.getCrossrefMailto();
    final scopusState = await _keyStore.isScopusEnabled();

    _elsevierKey = savedKey ?? '';
    _crossrefMailto = savedMail ?? '';
    _scopusEnabled = scopusState && (savedKey?.isNotEmpty ?? false);

    _isLoading = false;
    _initialized = true;
    notifyListeners();
  }

  void changeLocale(Locale locale) {
    if (_selectedLocale == locale) return;
    _selectedLocale = locale;
    notifyListeners();
  }

  void updateElsevierKey(String value) {
    _elsevierKey = value;
    notifyListeners();
  }

  void updateCrossrefMailto(String value) {
    _crossrefMailto = value;
    notifyListeners();
  }

  void toggleScopus(bool enabled) {
    _scopusEnabled = enabled;
    notifyListeners();
  }

  Future<void> completeLanguageStep() async {
    _isSaving = true;
    notifyListeners();
    await _setLanguageUseCase.call(_selectedLocale);
    _isSaving = false;
    _currentStep = 1;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    _isSaving = true;
    notifyListeners();
    final key = _scopusEnabled ? _elsevierKey.trim() : '';
    await _keyStore.saveElsevierKey(key, scopusEnabled: _scopusEnabled);
    await _keyStore.saveCrossrefMailto(_crossrefMailto.trim());
    await _keyStore.markOnboardingCompleted();
    _isSaving = false;
    notifyListeners();
  }

  void restart() {
    _currentStep = 0;
    notifyListeners();
  }
}
