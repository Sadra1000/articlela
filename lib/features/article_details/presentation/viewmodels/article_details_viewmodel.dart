import 'package:flutter/foundation.dart';

import '../../data/services/abstract_fetcher.dart';

class ArticleDetailsViewModel extends ChangeNotifier {
  ArticleDetailsViewModel(this._fetcher);

  final IAbstractFetcher _fetcher;

  AbstractResult? _result;
  bool _isLoading = false;
  String? _error;

  AbstractResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(String doi) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
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

  void reset() {
    _result = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
