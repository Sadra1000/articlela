import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../article_details/data/services/google_translate_service.dart';

class PdfReaderViewModel extends ChangeNotifier {
  PdfReaderViewModel(this._translator);

  final ArticleTranslator _translator;

  File? _document;
  bool _isPickingFile = false;
  bool _isTranslating = false;
  String? _selectedText;
  String? _translation;
  String? _translationError;
  int _requestId = 0;

  File? get document => _document;
  bool get hasDocument => _document != null;
  bool get isPickingFile => _isPickingFile;
  bool get isTranslating => _isTranslating;
  String? get selectedText => _selectedText;
  String? get translation => _translation;
  String? get translationError => _translationError;
  bool get showTranslationSheet => (_selectedText ?? '').isNotEmpty;

  String? get fileName {
    final file = _document;
    if (file == null) {
      return null;
    }
    final segments = file.path.split(Platform.pathSeparator);
    return segments.isEmpty ? file.path : segments.last;
  }

  Future<bool?> pickDocument() async {
    if (_isPickingFile) {
      return null;
    }
    _isPickingFile = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }

      final filePath = result.files.single.path;
      if (filePath == null || filePath.isEmpty) {
        return false;
      }

      _document = File(filePath);
      _clearTranslationState();
      notifyListeners();
      return true;
    } catch (error) {
      return false;
    } finally {
      _isPickingFile = false;
      notifyListeners();
    }
  }

  Future<void> handleSelection(
    String? selection, {
    required String targetLanguage,
  }) async {
    final cleaned = _sanitizeSelection(selection);
    if (cleaned == null) {
      clearSelection();
      return;
    }

    if (cleaned == _selectedText && _translation != null) {
      _translationError = null;
      _isTranslating = false;
      notifyListeners();
      return;
    }

    _selectedText = cleaned;
    _translation = null;
    _translationError = null;
    _isTranslating = true;
    final currentRequest = ++_requestId;
    notifyListeners();

    try {
      final translated = await _translator.translate(
        text: cleaned,
        sourceLanguage: 'auto',
        targetLanguage: targetLanguage.isNotEmpty ? targetLanguage : 'fa',
      );

      if (_requestId != currentRequest) {
        return;
      }

      _translation = translated;
    } catch (error) {
      if (_requestId != currentRequest) {
        return;
      }
      _translationError = error.toString();
    } finally {
      if (_requestId == currentRequest) {
        _isTranslating = false;
        notifyListeners();
      }
    }
  }

  void clearSelection() {
    _selectedText = null;
    _translation = null;
    _translationError = null;
    _isTranslating = false;
    _requestId++;
    notifyListeners();
  }

  void _clearTranslationState() {
    _selectedText = null;
    _translation = null;
    _translationError = null;
    _isTranslating = false;
    _requestId++;
  }

  String? _sanitizeSelection(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized.length > 120 ? normalized.substring(0, 120) : normalized;
  }
}
