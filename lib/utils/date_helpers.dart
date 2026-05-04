/// Shared date formatting and parsing helpers used across patient screens
/// and FirestoreService.

/// Formats a DateTime to "YYYY-MM-DD" string (used as the `fecha` field in Firestore).
String formatDateToString(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

/// Formats a DateTime to "HH:mm" string (used as the `hora` field in Firestore).
String formatTimeToString(DateTime date) {
  return "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}

/// Parses a "YYYY-MM-DD" string into a DateTime.
/// Returns null if the string is null or cannot be parsed.
DateTime? parseDate(String? fechaStr) {
  if (fechaStr == null) return null;
  try {
    final parts = fechaStr.split('-');
    if (parts.length != 3) return null;
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  } catch (_) {
    return null;
  }
}
