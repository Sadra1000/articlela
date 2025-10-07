import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../entities/keyword_group_entity.dart';
import '../entities/search_filter_entity.dart';

class SaveSearchPrefsUseCase {
  SaveSearchPrefsUseCase(this._prefs);

  final SharedPreferences _prefs;

  Future<void> save(SearchFilterEntity filter) async {
    final payload = {
      'fromYear': filter.fromYear,
      'toYear': filter.toYear,
      'documentTypes': filter.documentTypes,
      'groups': filter.groups
          .map((group) => {
                'id': group.id,
                'name': group.name,
                'keywords': group.keywords,
              })
          .toList(),
    };

    await _prefs.setString(AppConstants.searchPrefsKey, jsonEncode(payload));
  }

  SearchFilterEntity? load() {
    final raw = _prefs.getString(AppConstants.searchPrefsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final groups = (decoded['groups'] as List<dynamic>).map((group) {
        final groupMap = group as Map<String, dynamic>;
        return KeywordGroupEntity(
          id: groupMap['id'] as String,
          name: groupMap['name'] as String,
          keywords: (groupMap['keywords'] as List<dynamic>).cast<String>(),
        );
      }).toList();

      return SearchFilterEntity(
        groups: groups,
        fromYear: decoded['fromYear'] as int,
        toYear: decoded['toYear'] as int,
        documentTypes: (decoded['documentTypes'] as List<dynamic>).cast<String>(),
      );
    } catch (_) {
      return null;
    }
  }
}
