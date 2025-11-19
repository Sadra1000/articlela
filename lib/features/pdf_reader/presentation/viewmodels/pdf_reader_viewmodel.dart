import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/data/services/article_explainer.dart';
import '../../../../core/data/services/google_translate_service.dart';

class PdfReaderViewModel extends ChangeNotifier {
  PdfReaderViewModel(this._translator, this._explainer);

  final ArticleTranslator _translator;
  final ArticleExplainer _explainer;

  File? _document;
  bool _isPickingFile = false;
  bool _isTranslating = false;
  bool _isExplaining = false;
  String? _selectedText;
  String? _lastExplanation;

  File? get document => _document;
  bool get hasDocument => _document != null;
  bool get isPickingFile => _isPickingFile;
  bool get isTranslating => _isTranslating;
  bool get isExplaining => _isExplaining;
  String? get selectedText => _selectedText;
  String? get lastExplanation => _lastExplanation;
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

      final succeeded = await openDocument(filePath);
      return succeeded;
    } catch (error) {
      return false;
    } finally {
      _isPickingFile = false;
      notifyListeners();
    }
  }

  Future<bool> openDocument(String filePath) async {
    final normalized = filePath.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final lowerCasePath = normalized.toLowerCase();
    if (!lowerCasePath.endsWith('.pdf')) {
      return false;
    }
    final file = File(normalized);
    final exists = await file.exists();
    if (!exists) {
      return false;
    }

    _document = file;
    _clearTranslationState();
    notifyListeners();
    return true;
  }

  void updateSelection(String? selection) {
    final cleaned = _sanitizeSelection(selection);
    if (cleaned == null) {
      clearSelection();
      return;
    }

    if (cleaned == _selectedText) {
      return;
    }

    _selectedText = cleaned;
    _isTranslating = false;
    _clearExplanationState();
    notifyListeners();
  }

  bool get hasSelection => (_selectedText ?? '').isNotEmpty;

  void clearSelection() {
    _selectedText = null;
    _isTranslating = false;
    _clearExplanationState();
    notifyListeners();
  }

  Future<String> translateSelection() async {
    final text = _selectedText;
    if (text == null || text.isEmpty) {
      throw StateError('No selection available for translation');
    }
    if (_isTranslating) {
      throw StateError('Translation already in progress');
    }

    _isTranslating = true;
    notifyListeners();

    try {
      final translated = await _translator.translate(text: text);
      return translated.trim();
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  Future<String> explainSelection() async {
    final text = _selectedText;
    if (text == null || text.isEmpty) {
      throw StateError('No selection available for explanation');
    }
    if (_isExplaining) {
      throw StateError('Explanation already in progress');
    }

    _isExplaining = true;
    notifyListeners();

    try {
      final explanation = await _explainer.explain(text: text);
      final cleaned = explanation.trim();
      if (cleaned.isEmpty) {
        throw const FormatException('Empty explanation');
      }
      _lastExplanation = cleaned;
      return cleaned;
    } finally {
      _isExplaining = false;
      notifyListeners();
    }
  }

  void _clearTranslationState() {
    _selectedText = null;
    _isTranslating = false;
    _clearExplanationState();
  }

  void _clearExplanationState() {
    _isExplaining = false;
    _lastExplanation = null;
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
    return normalized;
  }
}
