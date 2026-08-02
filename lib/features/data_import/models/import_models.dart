import 'package:equatable/equatable.dart';

/// Represents a single row from the import file
class ImportRow extends Equatable {
  final int rowNumber;
  final Map<String, dynamic> data;
  final String entityType; // 'Team', 'Season', 'Player', 'Game', 'GameEvent'
  final ImportRowStatus status;
  final List<ValidationError> errors;
  final EntityMatch? match;

  const ImportRow({
    required this.rowNumber,
    required this.data,
    required this.entityType,
    this.status = ImportRowStatus.pending,
    this.errors = const [],
    this.match,
  });

  ImportRow copyWith({
    ImportRowStatus? status,
    List<ValidationError>? errors,
    EntityMatch? match,
  }) {
    return ImportRow(
      rowNumber: rowNumber,
      data: data,
      entityType: entityType,
      status: status ?? this.status,
      errors: errors ?? this.errors,
      match: match ?? this.match,
    );
  }

  @override
  List<Object?> get props =>
      [rowNumber, data, entityType, status, errors, match];
}

enum ImportRowStatus {
  pending,
  validating,
  validated,
  matching,
  matched,
  importing,
  success,
  skipped,
  error,
}

/// Validation error for a specific field
class ValidationError extends Equatable {
  final String field;
  final String message;
  final String? suggestedFix;
  final ValidationErrorSeverity severity;

  const ValidationError({
    required this.field,
    required this.message,
    this.suggestedFix,
    this.severity = ValidationErrorSeverity.error,
  });

  @override
  List<Object?> get props => [field, message, suggestedFix, severity];
}

enum ValidationErrorSeverity {
  error,
  warning,
  info,
}

/// Entity matching result
class EntityMatch extends Equatable {
  final String entityType;
  final int? existingId;
  final String? existingName;
  final double confidence; // 0.0 to 1.0
  final MatchType matchType;
  final Map<String, dynamic>? existingData;

  const EntityMatch({
    required this.entityType,
    this.existingId,
    this.existingName,
    required this.confidence,
    required this.matchType,
    this.existingData,
  });

  bool get isExactMatch => confidence >= 0.95;
  bool get isProbableMatch => confidence >= 0.7 && confidence < 0.95;
  bool get isNoMatch => confidence < 0.7;

  @override
  List<Object?> get props => [
        entityType,
        existingId,
        existingName,
        confidence,
        matchType,
        existingData,
      ];
}

enum MatchType {
  exact,
  fuzzy,
  none,
  createNew,
}

/// Overall import result
class ImportResult extends Equatable {
  final String importId;
  final DateTime timestamp;
  final String fileName;
  final String entityType;
  final int totalRows;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final List<ImportRow> rows;
  final Duration duration;
  final String? userId;

  const ImportResult({
    required this.importId,
    required this.timestamp,
    required this.fileName,
    required this.entityType,
    required this.totalRows,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    required this.rows,
    required this.duration,
    this.userId,
  });

  List<ImportRow> get errorRows =>
      rows.where((r) => r.status == ImportRowStatus.error).toList();

  List<ImportRow> get successRows =>
      rows.where((r) => r.status == ImportRowStatus.success).toList();

  List<ImportRow> get skippedRows =>
      rows.where((r) => r.status == ImportRowStatus.skipped).toList();

  Map<String, dynamic> toMap() {
    return {
      'importId': importId,
      'timestamp': timestamp.toIso8601String(),
      'fileName': fileName,
      'entityType': entityType,
      'totalRows': totalRows,
      'successCount': successCount,
      'skippedCount': skippedCount,
      'errorCount': errorCount,
      'duration': duration.inMilliseconds,
      'userId': userId,
    };
  }

  @override
  List<Object?> get props => [
        importId,
        timestamp,
        fileName,
        entityType,
        totalRows,
        successCount,
        skippedCount,
        errorCount,
        duration,
        userId,
      ];
}

/// Configuration for import process
class ImportConfig {
  final int batchSize;
  final int batchDelayMs;
  final bool skipOnError;
  final bool validateOnly;
  final Map<String, String>? columnMapping;

  const ImportConfig({
    this.batchSize = 50,
    this.batchDelayMs = 100,
    this.skipOnError = true,
    this.validateOnly = false,
    this.columnMapping,
  });
}

/// CSV template definition
class CsvTemplate {
  final String entityType;
  final List<String> requiredColumns;
  final List<String> optionalColumns;
  final Map<String, String> columnDescriptions;
  final Map<String, String> exampleValues;

  const CsvTemplate({
    required this.entityType,
    required this.requiredColumns,
    required this.optionalColumns,
    required this.columnDescriptions,
    required this.exampleValues,
  });

  List<String> get allColumns => [...requiredColumns, ...optionalColumns];
}
