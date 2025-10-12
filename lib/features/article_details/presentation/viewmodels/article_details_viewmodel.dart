import 'package:flutter/foundation.dart';

import '../../data/services/abstract_fetcher.dart';
import '../../data/services/google_translate_service.dart';

class ArticleDetailsViewModel extends ChangeNotifier {
  ArticleDetailsViewModel(this._fetcher, this._translator);

  final IAbstractFetcher _fetcher;
  final ArticleTranslator _translator;

  AbstractResult? _result;
  bool _isLoading = false;
  String? _error;
  bool _isTranslating = false;
  String? _translatedAbstract;
  String? _translationError;

  AbstractResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTranslating => _isTranslating;
  String? get translatedAbstract => _translatedAbstract;
  String? get translationError => _translationError;
  bool get hasTranslation => (_translatedAbstract ?? '').isNotEmpty;

  Future<void> load(String doi) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _clearTranslation();
    notifyListeners();
    try {
      _result = await _fetcher.fetchByDoi(doi);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> translateAbstract({
    String sourceLanguage = 'en',
    String targetLanguage = 'fa',
  }) async {
    if (_isTranslating) return;
    final abstract = _result?.abstractText;
    if (abstract == null || abstract.trim().isEmpty) {
      return;
    }

    _isTranslating = true;
    _translationError = null;
    notifyListeners();

    try {
      final translated = await _translator.translate(
        text: abstract,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      _translatedAbstract = translated;
    } on ArgumentError {
      _translationError = 'translation_failed';
    } on FormatException {
      _translationError = 'translation_failed';
    } catch (error) {
      _translationError = error.toString();
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _error = null;
    _isLoading = false;
    _clearTranslation();
    notifyListeners();
  }

  void _clearTranslation() {
    _translatedAbstract = null;
    _translationError = null;
    _isTranslating = false;
  }
}
