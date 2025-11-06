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

  File? get document => _document;
  bool get hasDocument => _document != null;
  bool get isPickingFile => _isPickingFile;
  bool get isTranslating => _isTranslating;
  String? get selectedText => _selectedText;
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

    

    _selectedText = cleaned;
    _isTranslating = false;
    notifyListeners();
  }

  bool get hasSelection => (_selectedText ?? '').isNotEmpty;

  void clearSelection() {
    _selectedText = null;
    _isTranslating = false;
    notifyListeners();
  }

  void _clearTranslationState() {
    _selectedText = null;
    _isTranslating = false;
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
