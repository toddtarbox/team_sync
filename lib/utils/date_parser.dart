/// Utility for parsing dates from various formats
class DateParser {
  /// Parse date from various formats
  /// Supports: YYYY-MM-DD, MM/DD/YYYY, MM.DD.YYYY, YYYY-MM-DDTHH:MM:SS, M/D/YYYY, M.D.YYYY
  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    final trimmed = dateStr.trim();

    // Try ISO8601 format first (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)
    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) return isoDate;

    // Try MM.DD.YYYY or M.D.YYYY format
    if (trimmed.contains('.')) {
      final parts = trimmed.split('.');
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          try {
            return DateTime(year, month, day);
          } catch (e) {
            return null;
          }
        }
      }
    }

    // Try MM/DD/YYYY or M/D/YYYY format
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          try {
            return DateTime(year, month, day);
          } catch (e) {
            return null;
          }
        }
      }
    }

    // Try MM-DD-YYYY or M-D-YYYY format
    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 3) {
        // Check if it's MM-DD-YYYY (not YYYY-MM-DD which would have been caught by ISO8601)
        final first = int.tryParse(parts[0]);
        final second = int.tryParse(parts[1]);
        final third = int.tryParse(parts[2]);

        if (first != null && second != null && third != null) {
          // If first part is <= 12 and third part is a 4-digit year, assume MM-DD-YYYY
          if (first <= 12 && third >= 1000) {
            try {
              return DateTime(third, first, second);
            } catch (e) {
              return null;
            }
          }
        }
      }
    }

    return null;
  }

  /// Parse and convert to ISO8601 string, or return null if invalid
  static String? parseToIso8601(String? dateStr) {
    final date = parse(dateStr);
    return date?.toIso8601String();
  }
}
