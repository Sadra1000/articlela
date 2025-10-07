import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/keyword_group_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../../domain/usecases/save_search_prefs_usecase.dart';

class KeywordConfigViewModel extends ChangeNotifier {
  KeywordConfigViewModel({
    required SaveSearchPrefsUseCase saveSearchPrefsUseCase,
  }) : _saveSearchPrefsUseCase = saveSearchPrefsUseCase;

  final SaveSearchPrefsUseCase _saveSearchPrefsUseCase;

  final List<KeywordGroupEntity> _groups = [];
  final List<String> _selectedDocTypes = <String>[
    'journal_article',
    'review',
  ];

  int _fromYear = AppConstants.defaultFromYear;
  int _toYear = AppConstants.currentYear;
  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _error;
  int _groupCounter = 1;

  static const List<String> availableDocTypes = [
    'journal_article',
    'review',
    'book',
    'conference',
    'report',
    'thesis',
    'other',
  ];

  List<KeywordGroupEntity> get groups => List.unmodifiable(_groups);
  int get fromYear => _fromYear;
  int get toYear => _toYear;
  List<String> get selectedDocTypes => List.unmodifiable(_selectedDocTypes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_hasInitialized) return;
    _isLoading = true;
    notifyListeners();
    final stored = _saveSearchPrefsUseCase.load();
    if (stored != null) {
      _groups
        ..clear()
        ..addAll(stored.groups.map(
          (group) => KeywordGroupEntity(
            id: group.id,
            name: group.name,
            keywords: List<String>.from(group.keywords),
          ),
        ));
      _fromYear = stored.fromYear;
      _toYear = stored.toYear;
      _selectedDocTypes
        ..clear()
        ..addAll(stored.documentTypes);
      _groupCounter = _groups.length + 1;
      for (final group in _groups) {
        if (group.keywords.isEmpty) {
          group.keywords.add('');
        }
      }
    }

    if (_groups.isEmpty) {
      addGroup();
    }

    _isLoading = false;
    _hasInitialized = true;
    notifyListeners();
  }

  void addGroup() {
    final name = 'Group ${_groups.length + 1}';
    final group = KeywordGroupEntity(
      id: 'group_${_groupCounter++}',
      name: name,
      keywords: <String>[],
    );
    group.keywords.add('');
    _groups.add(group);
    notifyListeners();
  }

  void renameGroup(String groupId, String newName) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => throw ArgumentError('Group not found'));
    group.name = newName.trim().isEmpty ? group.name : newName.trim();
    notifyListeners();
  }

  void removeGroup(String groupId) {
    _groups.removeWhere((g) => g.id == groupId);
    if (_groups.isEmpty) {
      addGroup();
    } else {
      notifyListeners();
    }
  }

  void addKeyword(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    group.keywords.add('');
    notifyListeners();
  }

  void updateKeyword(String groupId, int index, String value) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (index >= 0 && index < group.keywords.length) {
      group.keywords[index] = value;
      notifyListeners();
    }
  }

  void removeKeyword(String groupId, int index) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (index >= 0 && index < group.keywords.length) {
      group.keywords.removeAt(index);
      notifyListeners();
    }
  }

  void setYearRange(int from, int to) {
    _fromYear = from;
    _toYear = to;
    notifyListeners();
  }

  void toggleDocumentType(String docTypeId) {
    if (_selectedDocTypes.contains(docTypeId)) {
      _selectedDocTypes.remove(docTypeId);
    } else {
      _selectedDocTypes.add(docTypeId);
    }
    notifyListeners();
  }

  String? validate() {
    if (_groups.isEmpty) {
      return 'no_groups';
    }
    for (final group in _groups) {
      final keywords = group.keywords.where((keyword) => Validators.isNotEmpty(keyword)).toList();
      if (keywords.isEmpty) {
        return 'empty_keywords';
      }
    }
    return null;
  }

  SearchFilterEntity buildFilter() {
    final preparedGroups = _groups
        .map(
          (group) => KeywordGroupEntity(
            id: group.id,
            name: group.name,
            keywords: group.keywords.where((keyword) => Validators.isNotEmpty(keyword)).map((k) => k.trim()).toList(),
          ),
        )
        .where((group) => group.keywords.isNotEmpty)
        .toList();

    return SearchFilterEntity(
      groups: preparedGroups,
      fromYear: _fromYear,
      toYear: _toYear,
      documentTypes: List<String>.from(_selectedDocTypes),
    );
  }

  Future<void> persist() async {
    final filter = buildFilter();
    await _saveSearchPrefsUseCase.save(filter);
  }

  void setError(String? code) {
    _error = code;
    notifyListeners();
  }
}
