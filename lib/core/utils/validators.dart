class Validators {
  const Validators._();

  static bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final regex = RegExp(r'^[\\w\\.-]+@[\\w\\.-]+\\.[A-Za-z]{2,}$');
    return regex.hasMatch(value.trim());
  }

  static bool isNotEmpty(String? value) => value?.trim().isNotEmpty ?? false;

  static bool hasKeywords(List<List<String>> groups) {
    if (groups.isEmpty) {
      return false;
    }
    for (final group in groups) {
      if (group.isEmpty) {
        return false;
      }
    }
    return true;
  }
}
