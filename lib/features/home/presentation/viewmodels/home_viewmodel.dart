import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeViewModel extends ChangeNotifier {
  String _version = '';
  bool _isLoading = false;

  String get version => _version;
  bool get isLoading => _isLoading;

  Future<void> loadVersion() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version} (${info.buildNumber})';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
