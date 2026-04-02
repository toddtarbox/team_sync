import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/import_models.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/comprehensive_season_parser.dart';
import 'package:team_sync/services/csv_parser_service.dart';
import 'package:team_sync/services/csv_template_service.dart';
import 'package:team_sync/services/data_importer_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/error_csv_exporter_service.dart';
import 'package:team_sync/utils/date_parser.dart';
import 'package:team_sync/widgets/bound_import_dialog.dart';
import 'package:team_sync/widgets/player_merger_tool.dart';

/// Tracks the import status of a single file
class FileImportTask {
  final String fileName;
  final Uint8List bytes;
  ImportStatus status;
  List<ImportRow>? parsedRows;
  ImportResult? result;
  String? errorMessage;

  FileImportTask({
    required this.fileName,
    required this.bytes,
    this.status = ImportStatus.pending,
    this.parsedRows,
    this.result,
    this.errorMessage,
  });
}

enum ImportStatus {
  pending,
  parsing,
  parsed,
  importing,
  completed,
  failed,
}

class DataImportPage extends StatefulWidget {
  final Team? team;

  const DataImportPage({super.key, this.team});

  @override
  State<DataImportPage> createState() => _DataImportPageState();
}

class _DataImportPageState extends State<DataImportPage> {
  final CsvParserService _parser = CsvParserService();
  final CsvTemplateService _templateService = CsvTemplateService();
  final DataImporterService _importer = DataImporterService();
  final ErrorCsvExporterService _exporter = ErrorCsvExporterService();

  String _selectedEntityType = 'Season';

  // Single file import (legacy)
  List<ImportRow>? _parsedRows;
  ImportResult? _importResult;

  // Multiple file import (new)
  List<FileImportTask> _fileImportTasks = [];
  bool _isImporting = false;
  String _progressMessage = '';
  int _processedRows = 0;
  int _totalRows = 0;
  bool _allowMultipleFiles = true;

  final List<String> _entityTypes = [
    'Team',
    'Season',
    'Player',
    'Game',
    'GameEvent',
  ];

  @override
  void initState() {
    super.initState();
    _importer.progressStream.listen((progress) {
      setState(() {
        _progressMessage = progress.message ?? '';
        _processedRows = progress.processed;
        _totalRows = progress.total;
      });
    });
  }

  @override
  void dispose() {
    _importer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.dataImport),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEntityTypeSelector(),
            const SizedBox(height: 24),
            _buildTemplateSection(),
            const SizedBox(height: 24),
            _buildToolsSection(),
            const SizedBox(height: 24),
            _buildFileUploadSection(),
            if (_parsedRows != null) ...[
              const SizedBox(height: 24),
              _buildDataPreview(),
              const SizedBox(height: 24),
              _buildImportButton(),
            ],
            if (_fileImportTasks.isNotEmpty && _parsedRows == null) ...[
              const SizedBox(height: 24),
              _buildMultipleFileImportButton(),
            ],
            if (_isImporting) ...[
              const SizedBox(height: 24),
              _buildProgressIndicator(),
            ],
            if (_importResult != null) ...[
              const SizedBox(height: 24),
              _buildResultsSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntityTypeSelector() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Entity Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedEntityType,
              decoration: InputDecoration(
                labelText: loc.entityType,
                border: OutlineInputBorder(),
              ),
              items: _entityTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEntityType = value!;
                  _parsedRows = null;
                  _importResult = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV Template',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Download a blank CSV template with proper headers and example data for $_selectedEntityType.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _downloadTemplate,
              icon: const Icon(Icons.download),
              label: Text(loc.downloadTemplate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Verification Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tools to help verify your imported data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _findGamesWithNoEvents,
              icon: const Icon(Icons.search),
              label: const Text('Find Games With No Events'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _openPlayerMergerTool,
              icon: const Icon(Icons.merge),
              label: const Text('Merge Duplicate Players'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _findAndCreateMissingPlayers,
              icon: const Icon(Icons.person_add),
              label: const Text('Find & Create Missing Player Records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fixCorruptPlayerRecords,
              icon: const Icon(Icons.healing),
              label: const Text('Fix Corrupt Player Records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openBoundImportDialog,
              icon: const Icon(Icons.public),
              label: const Text('Import from Bound'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload CSV File(s)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(loc.multipleFiles, style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _allowMultipleFiles,
                      onChanged: _isImporting
                          ? null
                          : (value) {
                              setState(() {
                                _allowMultipleFiles = value;
                                if (!value) {
                                  // Clear multiple file tasks when switching to single mode
                                  _fileImportTasks.clear();
                                }
                              });
                            },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Comma-delimited CSV format',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(
                  _allowMultipleFiles ? 'Select CSV Files' : 'Select CSV File'),
            ),
            if (_fileImportTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Selected Files (${_fileImportTasks.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._fileImportTasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return _buildFileTaskItem(index, task);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    if (_parsedRows == null || _parsedRows!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Preview (${_parsedRows!.length} rows)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: _buildPreviewColumns(),
                    rows: _buildPreviewRows(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildPreviewColumns() {
    if (_parsedRows == null || _parsedRows!.isEmpty) return [];

    final firstRow = _parsedRows!.first;
    return [
      const DataColumn(label: Text('Row')),
      ...firstRow.data.keys.map((key) => DataColumn(label: Text(key))),
    ];
  }

  List<DataRow> _buildPreviewRows() {
    if (_parsedRows == null) return [];

    return _parsedRows!.take(10).map((row) {
      return DataRow(
        cells: [
          DataCell(Text(row.rowNumber.toString())),
          ...row.data.values
              .map((value) => DataCell(Text(value?.toString() ?? ''))),
        ],
      );
    }).toList();
  }

  Widget _buildImportButton() {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isImporting ? null : _startImport,
          icon: const Icon(Icons.cloud_upload),
          label: Text(loc.startImport),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _isImporting ? null : _validateOnly,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(loc.validateOnly),
        ),
        if (_isImporting) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _cancelImport,
            icon: const Icon(Icons.cancel),
            label: Text(loc.cancel),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_totalRows > 0)
              LinearProgressIndicator(
                value: _processedRows / _totalRows,
              ),
            const SizedBox(height: 8),
            Text('$_processedRows / $_totalRows rows processed'),
            if (_progressMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _progressMessage,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    final loc = AppLocalizations.of(context)!;
    if (_importResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
                'Total Rows', _importResult!.totalRows, Colors.blue),
            _buildResultRow(
                'Successful', _importResult!.successCount, Colors.green),
            _buildResultRow(
                'Skipped', _importResult!.skippedCount, Colors.orange),
            _buildResultRow('Errors', _importResult!.errorCount, Colors.red),
            const SizedBox(height: 12),
            Text('Duration: ${_importResult!.duration.inSeconds} seconds'),
            if (_importResult!.skippedCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Skipped Rows',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_importResult!.skippedRows
                  .take(10)
                  .map((row) => _buildErrorDetail(row))),
              if (_importResult!.skippedRows.length > 10)
                Text(
                    '... and ${_importResult!.skippedRows.length - 10} more skipped rows'),
            ],
            if (_importResult!.errorCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Error Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_importResult!.errorRows
                  .take(5)
                  .map((row) => _buildErrorDetail(row))),
              if (_importResult!.errorRows.length > 5)
                Text(
                    '... and ${_importResult!.errorRows.length - 5} more errors'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _downloadErrorCsv,
                icon: const Icon(Icons.download),
                label: Text(loc.downloadErrorReport),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDetail(ImportRow row) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text('Row ${row.rowNumber}'),
        subtitle: Text(
          row.errors.map((e) => '${e.field}: ${e.message}').join('; '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final fileName =
          '${_selectedEntityType.toLowerCase()}_import_template.csv';
      await _templateService.downloadTemplate(_selectedEntityType, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading template: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
        allowMultiple: _allowMultipleFiles,
      );

      if (result != null && result.files.isNotEmpty) {
        if (_allowMultipleFiles && result.files.length > 1) {
          // Multiple files selected - add them as tasks
          final tasks = result.files
              .where((file) => file.bytes != null)
              .map((file) => FileImportTask(
                    fileName: file.name,
                    bytes: file.bytes!,
                  ))
              .toList();

          setState(() {
            _fileImportTasks = tasks;
            _parsedRows = null;
            _importResult = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected ${tasks.length} files for import'),
              ),
            );
          }
        } else {
          // Single file selected - use legacy behavior
          final bytes = result.files.first.bytes!;

          // Detect content to show user what format was detected
          final content = utf8.decode(bytes);

          // Check if this is a comprehensive season format (has section headers)
          final isComprehensiveSeason = content.contains('[SEASON]') ||
              content.contains('[ROSTER]') ||
              content.contains('[SCHEDULE]') ||
              content.contains('[GAME]') ||
              content.contains('[GAME EVENTS]');

          if (isComprehensiveSeason) {
            // Use comprehensive season parser
            try {
              final comprehensiveParser = ComprehensiveSeasonParser();
              final comprehensiveResult =
                  await comprehensiveParser.parseSeasonFile(
                fileBytes: bytes,
                homeTeamId: 1, // TODO: Get from context or prompt user
              );

              // Check if this is a game event import (has gameMetadata but no season/game rows)
              if (comprehensiveResult.gameMetadata != null &&
                  comprehensiveResult.seasonRows.isEmpty &&
                  comprehensiveResult.gameRows.isEmpty) {
                // This is a game event import
                await _importGameEvents(comprehensiveResult);
              } else {
                // This is a full season import
                await _importComprehensiveSeason(comprehensiveResult);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Parsed: ${comprehensiveResult.seasonRows.length} season(s), '
                      '${comprehensiveResult.playerRows.length} player(s), '
                      '${comprehensiveResult.gameRows.length} game(s), '
                      '${comprehensiveResult.eventRows.length} event(s)',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error parsing comprehensive season: $e')),
                );
              }
            }
          } else {
            // Use standard CSV parser
            final rows = await _parser.parseCsv(
              fileBytes: bytes,
              entityType: _selectedEntityType,
            );

            setState(() {
              _parsedRows = rows;
              _importResult = null;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Parsed ${rows.length} rows from CSV file')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing CSV: $e')),
        );
      }
    }
  }

  void _openBoundImportDialog() {
    // Get current IDs if available, else default (or prompt)
    // Note: DataImportPage doesn't seemingly hold seasonId in state easily,
    // assuming it might be available in widget.team context or we prompt.
    // For now, attempting to use widget.team.currentSeasonId if defined.

    // Fallback ID validation
    if (widget.team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No team loaded context for import.')),
      );
      return;
    }

    // We assume current season is passed, or try to infer.
    // If team!.currentSeasonId is missing, we might use a SeasonService to find it,
    // but for now let's check if we can pass just teamId and let User pick season or use default.
    // Actually, checking Team model shows no currentSeasonId.
    // We will just pass teamId and -1 for seasonId and let the dialog handle selection or default.
    final teamId = widget.team!.id;
    // Attempt to find a season ID from context or default
    final seasonId = -1; // Dialog should handle or we prompt user

    // Optional: Get actual season year from Season model if possible.
    // Assuming '2025-26' for defaults if not found, but it's passed as null let the dialog handle or text field.

    showDialog(
      context: context,
      builder: (context) => BoundImportDialog(
        teamId: teamId,
        seasonId: seasonId,
        seasonYear: null,
      ),
    );
  }

  Future<void> _startImport() async {
    if (_parsedRows == null) return;

    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      final result = await _importer.importData(
        rows: _parsedRows!,
        fileName: 'import_${DateTime.now().millisecondsSinceEpoch}.csv',
        entityType: _selectedEntityType,
      );

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: ${result.successCount} success, ${result.errorCount} errors',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _validateOnly() async {
    if (_parsedRows == null) return;

    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      final result = await _importer.importData(
        rows: _parsedRows!,
        fileName: 'validation_${DateTime.now().millisecondsSinceEpoch}.csv',
        entityType: _selectedEntityType,
        config: const ImportConfig(validateOnly: true),
      );

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Validation completed: ${result.successCount} valid, ${result.errorCount} errors',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation failed: $e')),
        );
      }
    }
  }

  void _cancelImport() {
    _importer.cancelImport();
  }

  Future<void> _downloadErrorCsv() async {
    if (_importResult == null || _importResult!.errorRows.isEmpty) return;

    try {
      await _exporter.downloadErrorCsv(
        errorRows: _importResult!.errorRows,
        fileName: 'import_errors_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error report downloaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }

  Widget _buildFileTaskItem(int index, FileImportTask task) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (task.status) {
      case ImportStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case ImportStatus.parsing:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Parsing...';
        break;
      case ImportStatus.parsed:
        statusColor = Colors.lightBlue;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Parsed';
        break;
      case ImportStatus.importing:
        statusColor = Colors.orange;
        statusIcon = Icons.upload;
        statusText = 'Importing...';
        break;
      case ImportStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case ImportStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(statusIcon, color: statusColor),
        title: Text(task.fileName),
        subtitle: task.errorMessage != null
            ? Text(
                task.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(statusText, style: TextStyle(color: statusColor)),
        trailing: task.result != null
            ? Text(
                '${task.result!.successCount}/${task.result!.totalRows}',
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }

  Widget _buildMultipleFileImportButton() {
    final pendingTasks = _fileImportTasks
        .where((t) =>
            t.status == ImportStatus.pending || t.status == ImportStatus.parsed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ready to Import ${_fileImportTasks.length} Files',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _startMultipleFileImport,
                    icon: const Icon(Icons.upload_file),
                    label: Text('Import All ($pendingTasks files)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isImporting ? null : _parseAllFiles,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Parse & Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isImporting
                  ? null
                  : () {
                      setState(() {
                        _fileImportTasks.clear();
                      });
                    },
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _parseAllFiles() async {
    setState(() {
      _isImporting = true;
      _progressMessage = 'Parsing files...';
    });

    try {
      for (int i = 0; i < _fileImportTasks.length; i++) {
        final task = _fileImportTasks[i];

        setState(() {
          task.status = ImportStatus.parsing;
          _progressMessage =
              'Parsing ${task.fileName} (${i + 1}/${_fileImportTasks.length})';
        });

        try {
          final content = utf8.decode(task.bytes);
          final isComprehensiveSeason = content.contains('[SEASON]') ||
              content.contains('[ROSTER]') ||
              content.contains('[SCHEDULE]') ||
              content.contains('[GAME]') ||
              content.contains('[GAME EVENTS]');

          if (isComprehensiveSeason) {
            final comprehensiveParser = ComprehensiveSeasonParser();
            final result = await comprehensiveParser.parseSeasonFile(
              fileBytes: task.bytes,
              homeTeamId: 1,
            );

            // Combine all rows for preview
            final allRows = <ImportRow>[
              ...result.seasonRows,
              ...result.playerRows,
              ...result.opponentRows,
              ...result.gameRows,
              ...result.eventRows,
            ];

            task.parsedRows = allRows;
            task.status = ImportStatus.parsed;
          } else {
            final rows = await _parser.parseCsv(
              fileBytes: task.bytes,
              entityType: _selectedEntityType,
            );
            task.parsedRows = rows;
            task.status = ImportStatus.parsed;
          }
        } catch (e) {
          task.status = ImportStatus.failed;
          task.errorMessage = 'Parse error: $e';
          debugPrint('Error parsing ${task.fileName}: $e');
        }
      }

      setState(() {
        _isImporting = false;
        _progressMessage = '';
      });

      if (mounted) {
        final successCount = _fileImportTasks
            .where((t) => t.status == ImportStatus.parsed)
            .length;
        final failCount = _fileImportTasks
            .where((t) => t.status == ImportStatus.failed)
            .length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Parsed $successCount files successfully, $failCount failed'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing files: $e')),
        );
      }
    }
  }

  Future<void> _startMultipleFileImport() async {
    setState(() {
      _isImporting = true;
      _progressMessage = 'Starting import...';
    });

    try {
      int totalSuccess = 0;
      int totalErrors = 0;
      int totalSkipped = 0;

      // Process files sequentially to maintain order and avoid DB conflicts
      for (int i = 0; i < _fileImportTasks.length; i++) {
        final task = _fileImportTasks[i];

        if (task.status == ImportStatus.failed) {
          continue; // Skip failed parse tasks
        }

        setState(() {
          task.status = ImportStatus.importing;
          _progressMessage =
              'Importing ${task.fileName} (${i + 1}/${_fileImportTasks.length})';
        });

        try {
          // Parse if not already parsed
          if (task.parsedRows == null) {
            final content = utf8.decode(task.bytes);
            final isComprehensiveSeason = content.contains('[SEASON]') ||
                content.contains('[ROSTER]') ||
                content.contains('[SCHEDULE]') ||
                content.contains('[GAME]') ||
                content.contains('[GAME EVENTS]');

            if (isComprehensiveSeason) {
              // Handle comprehensive season import
              await _importComprehensiveSeasonFile(task);
              task.status = ImportStatus.completed;
            } else {
              // Standard CSV import
              final rows = await _parser.parseCsv(
                fileBytes: task.bytes,
                entityType: _selectedEntityType,
              );

              final result = await _importer.importData(
                rows: rows,
                fileName: task.fileName,
                entityType: _selectedEntityType,
              );

              task.result = result;
              task.status = ImportStatus.completed;

              totalSuccess += result.successCount;
              totalErrors += result.errorCount;
              totalSkipped += result.skippedCount;
            }
          } else {
            // Already parsed, just import
            final content = utf8.decode(task.bytes);
            final isComprehensiveSeason = content.contains('[SEASON]') ||
                content.contains('[ROSTER]') ||
                content.contains('[SCHEDULE]') ||
                content.contains('[GAME]') ||
                content.contains('[GAME EVENTS]');

            if (isComprehensiveSeason) {
              await _importComprehensiveSeasonFile(task);
              task.status = ImportStatus.completed;
            } else {
              final result = await _importer.importData(
                rows: task.parsedRows!,
                fileName: task.fileName,
                entityType: _selectedEntityType,
              );

              task.result = result;
              task.status = ImportStatus.completed;

              totalSuccess += result.successCount;
              totalErrors += result.errorCount;
              totalSkipped += result.skippedCount;
            }
          }

          setState(() {}); // Update UI after each file
        } catch (e) {
          task.status = ImportStatus.failed;
          task.errorMessage = 'Import error: $e';
          debugPrint('Error importing ${task.fileName}: $e');
        }
      }

      setState(() {
        _isImporting = false;
        _progressMessage = '';
      });

      if (mounted) {
        final completedCount = _fileImportTasks
            .where((t) => t.status == ImportStatus.completed)
            .length;
        final failedCount = _fileImportTasks
            .where((t) => t.status == ImportStatus.failed)
            .length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $completedCount succeeded, $failedCount failed\n'
              'Total: $totalSuccess success, $totalErrors errors, $totalSkipped skipped',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Multiple file import failed: $e')),
        );
      }
    }
  }

  Future<void> _importComprehensiveSeasonFile(FileImportTask task) async {
    final comprehensiveParser = ComprehensiveSeasonParser();
    final comprehensiveResult = await comprehensiveParser.parseSeasonFile(
      fileBytes: task.bytes,
      homeTeamId: 1,
    );

    // Check if this is a game event import
    if (comprehensiveResult.gameMetadata != null &&
        comprehensiveResult.seasonRows.isEmpty &&
        comprehensiveResult.gameRows.isEmpty) {
      await _importGameEvents(comprehensiveResult);
    } else {
      // Full season import
      await _importComprehensiveSeason(comprehensiveResult);
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('Data Import Help'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'How to Import Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Select the entity type you want to import'),
                Text('2. Download the CSV template for that entity type'),
                Text('3. Fill in your data following the template format'),
                Text('4. Upload your completed CSV file'),
                Text('5. Review the data preview'),
                Text(
                    '6. Click "Validate Only" to check for errors, or "Start Import" to import'),
                SizedBox(height: 12),
                Text(
                  'Tips',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• All imported records will have isFromImport = true'),
                Text('• The system will match existing entities by name'),
                Text(
                    '• Errors will be skipped and can be exported for correction'),
                Text('• You can re-import corrected error files'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _findGamesWithNoEvents() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking games for events...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Query games
      List<Map<dynamic, dynamic>> gamesData = [];
      Set<int> gameIdsWithEvents = {};
      bool useTeamOptimization = widget.team != null;

      if (useTeamOptimization) {
        // Optimization: Fetch only this team's data
        // 1. Get seasons
        final seasons = await DatabaseService.instance.query(
          'Seasons',
          orderByChild: 'teamId',
          equalTo: widget.team!.id,
        );

        // 2. Get games for these seasons
        for (final season in seasons) {
          final seasonGames = await DatabaseService.instance.query(
            'Games',
            orderByChild: 'seasonId',
            equalTo: season['id'],
          );
          gamesData.addAll(seasonGames.cast<Map<dynamic, dynamic>>());
        }

        // 3. Get all events for this team to check attendance
        final teamEvents = await DatabaseService.instance.query(
          'Events',
          orderByChild: 'teamId',
          equalTo: widget.team!.id,
        );
        for (final event in teamEvents) {
          if (event['gameId'] != null) {
            gameIdsWithEvents.add(event['gameId'] as int);
          }
        }
      } else {
        // Legacy/Global: Query all games
        final allGames = await DatabaseService.instance.query('Games');
        gamesData = allGames.cast<Map<dynamic, dynamic>>();
      }

      final gamesWithNoEvents = <Map<String, dynamic>>[];

      for (final gameData in gamesData) {
        final gameId = gameData['id'] as int;

        // Handle gameStatus which might be stored as String or int in database
        final gameStatusValue = gameData['gameStatus'];
        int gameStatus;
        if (gameStatusValue is int) {
          gameStatus = gameStatusValue;
        } else if (gameStatusValue is String) {
          gameStatus = int.tryParse(gameStatusValue) ?? 0;
        } else {
          gameStatus = 0;
        }

        // Skip games that haven't been played yet (gameStatus == 0 means notStarted)
        if (gameStatus == 0) {
          continue;
        }

        // Check for events
        bool hasEvents = false;
        if (useTeamOptimization) {
          hasEvents = gameIdsWithEvents.contains(gameId);
        } else {
          // Slow check for global mode
          final events = await DatabaseService.instance.query(
            'Events',
            orderByChild: 'gameId',
            equalTo: gameId,
          );
          hasEvents = events.isNotEmpty;
        }

        if (!hasEvents) {
          // Load season and teams data for display
          final seasonId = gameData['seasonId'] as int;
          final homeTeamId = gameData['homeTeamId'] as int;
          final awayTeamId = gameData['awayTeamId'] as int;

          final seasonData = await DatabaseService.instance.query(
            'Seasons',
            orderByChild: 'id',
            equalTo: seasonId,
          );

          final homeTeamData = await DatabaseService.instance.query(
            'Teams',
            orderByChild: 'id',
            equalTo: homeTeamId,
          );

          final awayTeamData = await DatabaseService.instance.query(
            'Teams',
            orderByChild: 'id',
            equalTo: awayTeamId,
          );

          gamesWithNoEvents.add({
            'gameId': gameId,
            'date': gameData['date'],
            'season':
                seasonData.isNotEmpty ? seasonData.first['name'] : 'Unknown',
            'homeTeam': homeTeamData.isNotEmpty
                ? homeTeamData.first['shortName']
                : 'Unknown',
            'awayTeam': awayTeamData.isNotEmpty
                ? awayTeamData.first['shortName']
                : 'Unknown',
            'homeScore': gameData['homeTeamScore'] ?? 0,
            'awayScore': gameData['awayTeamScore'] ?? 0,
            'description': gameData['description'],
          });
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text('Games With No Events (${gamesWithNoEvents.length})'),
              content: SizedBox(
                width: double.maxFinite,
                child: gamesWithNoEvents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '✓ All games have events!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: gamesWithNoEvents.length,
                        itemBuilder: (context, index) {
                          final game = gamesWithNoEvents[index];
                          final date =
                              DateParser.parse(game['date'].toString());
                          final dateStr = date != null
                              ? '${date.month}/${date.day}/${date.year}'
                              : game['date'].toString();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                '${game['homeTeam']} vs ${game['awayTeam']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Game ID: ${game['gameId']}'),
                                  Text('Season: ${game['season']}'),
                                  Text('Date: $dateStr'),
                                  Text(
                                      'Score: ${game['homeScore']} - ${game['awayScore']}'),
                                  if (game['description'] != null &&
                                      game['description'].toString().isNotEmpty)
                                    Text('Description: ${game['description']}'),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                if (gamesWithNoEvents.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // Export to CSV
                      _exportGamesWithNoEvents(gamesWithNoEvents);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export to CSV'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.close),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportGamesWithNoEvents(
      List<Map<String, dynamic>> games) async {
    try {
      final fileName =
          'games_with_no_events_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Create export rows structure for the exporter service
      final exportRows = games.map((game) {
        final date = DateParser.parse(game['date'].toString());
        final dateStr = date != null
            ? '${date.month}/${date.day}/${date.year}'
            : game['date'].toString();
        return ImportRow(
          rowNumber: 0,
          data: {
            'gameId': game['gameId'].toString(),
            'season': game['season'].toString(),
            'date': dateStr,
            'homeTeam': game['homeTeam'].toString(),
            'awayTeam': game['awayTeam'].toString(),
            'homeScore': game['homeScore'].toString(),
            'awayScore': game['awayScore'].toString(),
            'description': game['description']?.toString() ?? '',
          },
          entityType: 'Game',
          status: ImportRowStatus.skipped,
          errors: [],
        );
      }).toList();

      await _exporter.downloadErrorCsv(
        errorRows: exportRows,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Games list exported to Downloads folder'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting games list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openPlayerMergerTool() {
    if (widget.team != null) {
      showPlayerMergerDialog(context, widget.team!);
    }
  }

  Future<void> _importComprehensiveSeason(
      ComprehensiveSeasonImport comprehensiveResult) async {
    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      int totalSuccess = 0;
      int totalErrors = 0;
      int totalSkipped = 0;
      final allProcessedRows = <ImportRow>[];

      // Step 1: Import Season
      int? createdSeasonId;
      if (comprehensiveResult.seasonRows.isNotEmpty) {
        debugPrint(
            'About to import ${comprehensiveResult.seasonRows.length} season(s)');
        debugPrint(
            'Season data before import: ${comprehensiveResult.seasonRows.first.data}');

        final seasonResult = await _importer.importData(
          rows: comprehensiveResult.seasonRows,
          fileName: 'season_${DateTime.now().millisecondsSinceEpoch}.csv',
          entityType: 'Season',
        );
        totalSuccess += seasonResult.successCount;
        totalErrors += seasonResult.errorCount;
        totalSkipped += seasonResult.skippedCount;
        allProcessedRows.addAll(seasonResult.rows);

        debugPrint(
            'Season import result: Success=${seasonResult.successCount}, Errors=${seasonResult.errorCount}, Skipped=${seasonResult.skippedCount}');

        // Check if season was skipped due to duplicate - if so, find existing season
        if (seasonResult.successCount == 0 && seasonResult.skippedCount > 0) {
          final skippedRow = seasonResult.rows.first;
          final isDuplicate = skippedRow.errors.any(
              (e) => e.field == 'name' && e.message.contains('already exists'));

          if (isDuplicate) {
            // Season already exists - find it and use its ID
            final seasonName =
                comprehensiveResult.seasonRows.first.data['name']?.toString();
            final teamId = comprehensiveResult.seasonRows.first.data['teamId'];

            debugPrint(
                'Season "$seasonName" already exists, finding existing season ID...');

            try {
              final existingSeasons = await DatabaseService.instance.query(
                'Seasons',
                orderByChild: 'teamId',
                equalTo: teamId,
              );

              final existingSeason = existingSeasons.firstWhere(
                (s) =>
                    s['name'].toString().toLowerCase() ==
                    seasonName?.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );

              if (existingSeason.isNotEmpty && existingSeason['id'] != null) {
                createdSeasonId = existingSeason['id'] as int?;
                debugPrint('Found existing season with ID: $createdSeasonId');

                // Delete all existing season data to avoid duplicates
                debugPrint(
                    'Deleting existing season data for season ID: $createdSeasonId');

                try {
                  // Delete game events
                  final existingEvents = await DatabaseService.instance.query(
                    'Events',
                    orderByChild: 'seasonId',
                    equalTo: createdSeasonId,
                  );
                  for (final event in existingEvents) {
                    if (event['id'] != null) {
                      await DatabaseService.instance.delete(
                        'Events',
                        orderByChild: 'id',
                        equalTo: event['id'],
                      );
                    }
                  }
                  debugPrint(
                      'Deleted ${existingEvents.length} existing events');

                  // Delete games
                  final existingGames = await DatabaseService.instance.query(
                    'Games',
                    orderByChild: 'seasonId',
                    equalTo: createdSeasonId,
                  );
                  for (final game in existingGames) {
                    if (game['id'] != null) {
                      await DatabaseService.instance.delete(
                        'Games',
                        orderByChild: 'id',
                        equalTo: game['id'],
                      );
                    }
                  }
                  debugPrint('Deleted ${existingGames.length} existing games');

                  // Delete players
                  final existingPlayers = await DatabaseService.instance.query(
                    'Players',
                    orderByChild: 'seasonId',
                    equalTo: createdSeasonId,
                  );
                  for (final player in existingPlayers) {
                    if (player['id'] != null) {
                      await DatabaseService.instance.delete(
                        'Players',
                        orderByChild: 'id',
                        equalTo: player['id'],
                      );
                    }
                  }
                  debugPrint(
                      'Deleted ${existingPlayers.length} existing players');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Re-importing season "$seasonName" (ID: $createdSeasonId). Deleted existing data: ${existingPlayers.length} players, ${existingGames.length} games, ${existingEvents.length} events.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error deleting existing season data: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Warning: Could not delete all existing season data: $e',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('Error finding existing season: $e');
            }
          }
        }

        // ABORT only if season had real errors (not duplicate) and we couldn't get a season ID
        if (seasonResult.successCount == 0 && createdSeasonId == null) {
          final errorDetails = seasonResult.rows.first.errors.isNotEmpty
              ? seasonResult.rows.first.errors
                  .map((e) => '${e.field}: ${e.message}')
                  .join(', ')
              : 'Unknown reason';

          debugPrint('ABORTING: Season import failed - $errorDetails');

          // Create failed result
          final failedResult = ImportResult(
            importId: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            fileName: 'comprehensive_season.csv',
            entityType: 'ComprehensiveSeason',
            totalRows: 1,
            successCount: 0,
            skippedCount: totalSkipped,
            errorCount: totalErrors,
            rows: allProcessedRows,
            duration: const Duration(seconds: 0),
          );

          setState(() {
            _importResult = failedResult;
            _isImporting = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Import aborted: Season $failedResult ($errorDetails). Cannot import dependent data without a valid season.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return; // Abort the import
        }

        debugPrint(
            'Season data after import: ${comprehensiveResult.seasonRows.first.data}');

        // Get the created season ID from the original row data (which was modified during import)
        if (comprehensiveResult.seasonRows.isNotEmpty &&
            comprehensiveResult.seasonRows.first.data['id'] != null) {
          createdSeasonId =
              comprehensiveResult.seasonRows.first.data['id'] as int?;
        }

        debugPrint('Created season with ID: $createdSeasonId');

        if (createdSeasonId != null) {
          debugPrint(
              'Setting seasonId=$createdSeasonId for ${comprehensiveResult.playerRows.length} players');
          debugPrint(
              'Setting seasonId=$createdSeasonId for ${comprehensiveResult.gameRows.length} games');
          debugPrint(
              'Setting seasonId=$createdSeasonId for ${comprehensiveResult.eventRows.length} events');

          // Step 2: Set seasonId for all players
          for (final playerRow in comprehensiveResult.playerRows) {
            playerRow.data['seasonId'] = createdSeasonId;
          }

          // Step 3: Set seasonId for all games
          for (final gameRow in comprehensiveResult.gameRows) {
            gameRow.data['seasonId'] = createdSeasonId;
          }

          // Step 4: Set seasonId for all events
          for (final eventRow in comprehensiveResult.eventRows) {
            eventRow.data['seasonId'] = createdSeasonId;
          }

          debugPrint(
              'Sample player data after seasonId set: ${comprehensiveResult.playerRows.first.data}');
        } else {
          debugPrint(
              'ERROR: Failed to get created season ID - aborting import!');

          // Create failed result
          final failedResult = ImportResult(
            importId: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            fileName: 'comprehensive_season.csv',
            entityType: 'ComprehensiveSeason',
            totalRows: 1,
            successCount: totalSuccess,
            skippedCount: totalSkipped,
            errorCount: totalErrors,
            rows: allProcessedRows,
            duration: const Duration(seconds: 0),
          );

          setState(() {
            _importResult = failedResult;
            _isImporting = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Import aborted: Failed to retrieve season ID. Cannot import dependent data without a valid season ID.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return; // Abort the import
        }
      }

      // Step 5: Import Opponents
      if (comprehensiveResult.opponentRows.isNotEmpty) {
        final opponentResult = await _importer.importData(
          rows: comprehensiveResult.opponentRows,
          fileName: 'opponents_${DateTime.now().millisecondsSinceEpoch}.csv',
          entityType: 'Team',
        );
        totalSuccess += opponentResult.successCount;
        totalErrors += opponentResult.errorCount;
        totalSkipped += opponentResult.skippedCount;
        allProcessedRows.addAll(opponentResult.rows);

        // Build opponent name -> ID mapping
        final opponentNameToId = <String, int>{};
        for (final row in opponentResult.successRows) {
          final name = row.data['fullName']?.toString();
          final id = row.data['id'];
          if (name != null && id != null) {
            opponentNameToId[name] = id as int;
          }
        }

        // Resolve opponent names to IDs in game rows
        debugPrint(
            'Resolving opponent names to IDs for ${comprehensiveResult.gameRows.length} games');
        for (final gameRow in comprehensiveResult.gameRows) {
          final opponentName = gameRow.data['opponentName']?.toString();
          if (opponentName != null) {
            final opponentId = opponentNameToId[opponentName];
            if (opponentId != null) {
              // Set the missing teamId based on location
              if (gameRow.data['homeTeamId'] == null) {
                gameRow.data['homeTeamId'] = opponentId;
              } else if (gameRow.data['awayTeamId'] == null) {
                gameRow.data['awayTeamId'] = opponentId;
              }
              gameRow.data.remove('opponentName'); // Clean up temp field
              debugPrint('  Resolved "$opponentName" to ID $opponentId');
            } else {
              debugPrint(
                  '  WARNING: Could not find opponent ID for "$opponentName"');
            }
          }
        }
      }

      // Step 6: Import Players
      if (comprehensiveResult.playerRows.isNotEmpty) {
        final playerResult = await _importer.importData(
          rows: comprehensiveResult.playerRows,
          fileName: 'players_${DateTime.now().millisecondsSinceEpoch}.csv',
          entityType: 'Player',
        );
        totalSuccess += playerResult.successCount;
        totalErrors += playerResult.errorCount;
        totalSkipped += playerResult.skippedCount;
        allProcessedRows.addAll(playerResult.rows);
      }

      // Step 7: Import Games
      if (comprehensiveResult.gameRows.isNotEmpty) {
        final gameResult = await _importer.importData(
          rows: comprehensiveResult.gameRows,
          fileName: 'games_${DateTime.now().millisecondsSinceEpoch}.csv',
          entityType: 'Game',
        );
        totalSuccess += gameResult.successCount;
        totalErrors += gameResult.errorCount;
        totalSkipped += gameResult.skippedCount;
        allProcessedRows.addAll(gameResult.rows);
      }

      // Step 8: Import Game Events
      if (comprehensiveResult.eventRows.isNotEmpty) {
        final eventResult = await _importer.importData(
          rows: comprehensiveResult.eventRows,
          fileName: 'events_${DateTime.now().millisecondsSinceEpoch}.csv',
          entityType: 'GameEvent',
        );
        totalSuccess += eventResult.successCount;
        totalErrors += eventResult.errorCount;
        totalSkipped += eventResult.skippedCount;
        allProcessedRows.addAll(eventResult.rows);
      }

      // Create combined result
      final combinedResult = ImportResult(
        importId: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        fileName: 'comprehensive_season.txt',
        entityType: 'ComprehensiveSeason',
        totalRows: allProcessedRows.length,
        successCount: totalSuccess,
        skippedCount: totalSkipped,
        errorCount: totalErrors,
        rows: allProcessedRows,
        duration: const Duration(seconds: 0), // Calculate if needed
      );

      setState(() {
        _importResult = combinedResult;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comprehensive import completed: $totalSuccess success, $totalErrors errors, $totalSkipped skipped',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comprehensive import failed: $e')),
        );
      }
    }
  }

  Future<void> _importGameEvents(
      ComprehensiveSeasonImport comprehensiveResult) async {
    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      final gameMetadata = comprehensiveResult.gameMetadata!;
      final seasonName = gameMetadata['seasonName']?.toString();
      final gameDate = gameMetadata['date']?.toString();
      final gameOpponent = gameMetadata['opponent']?.toString();

      debugPrint(
          'Importing game events for: Season=$seasonName, Date=$gameDate, Opponent=$gameOpponent');

      // Step 1: Find the season by name
      final seasons = await DatabaseService.instance.query('Seasons');
      final season = seasons.firstWhere(
        (s) => s['name']?.toString().toLowerCase() == seasonName?.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (season.isEmpty || season['id'] == null) {
        throw Exception('Season "$seasonName" not found');
      }

      final seasonId = season['id'] as int;
      final teamId = season['teamId'] as int;
      debugPrint('Found season ID: $seasonId, teamId: $teamId');

      // Step 2: Find the game by date and opponent
      final games = await DatabaseService.instance.query(
        'Games',
        orderByChild: 'seasonId',
        equalTo: seasonId,
      );

      // Get all teams to match opponent by name
      final allTeams = await DatabaseService.instance.query('Teams');
      final teamMap = <int, String>{};
      for (final team in allTeams) {
        if (team['id'] != null && team['fullName'] != null) {
          teamMap[team['id'] as int] = team['fullName'].toString();
        }
      }

      final game = games.firstWhere(
        (g) {
          final matchesDate = g['date']?.toString() == gameDate;
          if (!matchesDate) return false;

          // Match opponent by checking homeTeam or awayTeam names
          final homeTeamId = g['homeTeamId'] as int?;
          final awayTeamId = g['awayTeamId'] as int?;

          // Get team names
          final homeTeamName = homeTeamId != null ? teamMap[homeTeamId] : null;
          final awayTeamName = awayTeamId != null ? teamMap[awayTeamId] : null;

          // Check if either team matches the opponent name (case-insensitive)
          final matchesOpponent =
              (homeTeamName?.toLowerCase() == gameOpponent?.toLowerCase()) ||
                  (awayTeamName?.toLowerCase() == gameOpponent?.toLowerCase());

          debugPrint(
              '  Checking game: date=$matchesDate, home=$homeTeamName, away=$awayTeamName, matches=$matchesOpponent');

          return matchesDate && matchesOpponent;
        },
        orElse: () => <String, dynamic>{},
      );

      if (game.isEmpty || game['id'] == null) {
        throw Exception('Game not found for date $gameDate vs $gameOpponent');
      }

      final gameId = game['id'] as int;
      debugPrint('Found game ID: $gameId');

      // Step 3: Get all players for this season/team to map numbers to IDs
      final players = await DatabaseService.instance.query(
        'Players',
        orderByChild: 'seasonId',
        equalTo: seasonId,
      );

      final playerNumberToId = <int, int>{};
      for (final player in players) {
        final number = player['number'];
        final id = player['id'];
        if (number != null && id != null) {
          playerNumberToId[number as int] = id as int;
        }
      }
      debugPrint('Mapped ${playerNumberToId.length} player numbers to IDs');

      // Step 4: Delete existing events for this game to avoid duplicates
      debugPrint('Deleting existing events for game ID: $gameId');

      try {
        final existingEvents = await DatabaseService.instance.query(
          'Events',
          orderByChild: 'gameId',
          equalTo: gameId,
        );

        for (final event in existingEvents) {
          if (event['id'] != null) {
            await DatabaseService.instance.delete(
              'Events',
              orderByChild: 'id',
              equalTo: event['id'],
            );
          }
        }
        debugPrint('Deleted ${existingEvents.length} existing events');

        if (mounted && existingEvents.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleted ${existingEvents.length} existing event(s) for this game. Importing fresh data...',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting existing events: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Could not delete existing events: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Step 5: Set gameId, teamId, seasonId, and resolve player numbers to IDs
      for (final eventRow in comprehensiveResult.eventRows) {
        eventRow.data['gameId'] = gameId;
        eventRow.data['teamId'] = teamId;
        eventRow.data['seasonId'] = seasonId;

        // Resolve player number to player ID
        final playerNumber = eventRow.data['playerNumber'];
        if (playerNumber != null) {
          final playerId = playerNumberToId[playerNumber as int];
          if (playerId != null) {
            eventRow.data['playerId'] = playerId;
            eventRow.data.remove('playerNumber');
          } else {
            debugPrint(
                'WARNING: Could not find player ID for number $playerNumber');
          }
        }
      }

      // Step 6: Import the events
      debugPrint(
          'About to import ${comprehensiveResult.eventRows.length} event row(s)');

      if (comprehensiveResult.eventRows.isEmpty) {
        debugPrint('WARNING: No events to import!');
      } else {
        // Show sample event data
        final sampleEvent = comprehensiveResult.eventRows.first.data;
        debugPrint('Sample event data: $sampleEvent');
      }

      final eventResult = await _importer.importData(
        rows: comprehensiveResult.eventRows,
        fileName: 'game_events_${DateTime.now().millisecondsSinceEpoch}.csv',
        entityType: 'GameEvent',
      );

      debugPrint(
          'Import result: Success=${eventResult.successCount}, Errors=${eventResult.errorCount}, Skipped=${eventResult.skippedCount}');

      setState(() {
        _importResult = eventResult;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game event import completed: ${eventResult.successCount} events imported, ${eventResult.errorCount} errors, ${eventResult.skippedCount} skipped',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game event import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Find players who have events in imported seasons but no player record for that season
  Future<void> _findAndCreateMissingPlayers() async {
    try {
      setState(() {
        _isImporting = true;
      });

      debugPrint('=== Finding Missing Player Records ===');

      List<Map<dynamic, dynamic>> allEvents;
      List<Map<dynamic, dynamic>> allPlayers;

      // Optimization: Filter by team if available
      if (widget.team != null) {
        debugPrint('Fetching data for team ${widget.team!.id} only');
        allEvents = await DatabaseService.instance.query(
          'Events',
          orderByChild: 'teamId',
          equalTo: widget.team!.id,
        );
        allPlayers = await DatabaseService.instance.query(
          'Players',
          orderByChild: 'teamId',
          equalTo: widget.team!.id,
        );
      } else {
        debugPrint('Fetching ALL data (no team context - this may be slow)');
        allEvents = await DatabaseService.instance.query('Events');
        allPlayers = await DatabaseService.instance.query('Players');
      }

      debugPrint('Total events: ${allEvents.length}');
      debugPrint('Total player records: ${allPlayers.length}');

      // Build a set of existing player records (playerId + seasonId combinations)
      final existingPlayerSeasons = <String>{};
      for (var player in allPlayers) {
        final key = '${player['id']}_${player['seasonId']}';
        existingPlayerSeasons.add(key);
      }

      // Find events with players that don't have a player record for that season
      final missingPlayerSeasons = <String, Map<String, dynamic>>{};

      for (var event in allEvents) {
        final playerId = event['playerId'];
        final seasonId = event['seasonId'];

        if (playerId == null || playerId == -1 || playerId == -2) continue;
        if (seasonId == null) continue;

        final key = '${playerId}_$seasonId';

        if (!existingPlayerSeasons.contains(key)) {
          // Found an event for a player that doesn't have a record in this season
          if (!missingPlayerSeasons.containsKey(key)) {
            // Find the player's info from another season
            final existingPlayer = allPlayers.firstWhere(
              (p) => p['id'] == playerId,
              orElse: () => <String, dynamic>{},
            );

            if (existingPlayer.isNotEmpty) {
              missingPlayerSeasons[key] = {
                'id':
                    playerId, // Changed from 'playerId' to 'id' - this is what Player.fromMap expects
                'seasonId': seasonId,
                'firstName': existingPlayer['firstName'],
                'lastName': existingPlayer['lastName'],
                'number': existingPlayer['number'] ?? 0,
                'teamId': existingPlayer['teamId'],
              };
            }
          }
        }
      }

      debugPrint('Found ${missingPlayerSeasons.length} missing player records');

      if (missingPlayerSeasons.isEmpty) {
        setState(() {
          _isImporting = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Missing Players'),
              content: const Text(
                  'All players who have events already have player records for their seasons. '
                  'No action needed!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Missing Player Records?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${missingPlayerSeasons.length} players who have events but are missing player records for certain seasons.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Examples:'),
                const SizedBox(height: 8),
                ...missingPlayerSeasons.values.take(5).map((player) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${player['firstName']} ${player['lastName']} (#${player['number']}) - Season ${player['seasonId']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
                if (missingPlayerSeasons.length > 5)
                  Text(
                    '... and ${missingPlayerSeasons.length - 5} more',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Do you want to create these missing player records?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Players'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      // Create the missing player records
      int created = 0;
      int failed = 0;

      for (var playerData in missingPlayerSeasons.values) {
        try {
          await DatabaseService.instance.insert('Players', playerData);
          created++;
          debugPrint(
              'Created player: ${playerData['firstName']} ${playerData['lastName']} for season ${playerData['seasonId']}');
        } catch (e) {
          failed++;
          debugPrint('Failed to create player: $e');
        }
      }

      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Player Records Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully created: $created player records'),
                if (failed > 0)
                  Text(
                    'Failed: $failed player records',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Player stats should now display correctly for all imported seasons!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to find/create missing players: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Fix corrupt player records that are missing the 'id' field
  Future<void> _fixCorruptPlayerRecords() async {
    try {
      setState(() {
        _isImporting = true;
      });

      debugPrint('=== Fixing Corrupt Player Records ===');

      // Get all players
      final allPlayers = await DatabaseService.instance.query('Players');
      debugPrint('Total player records: ${allPlayers.length}');

      // Find players with missing 'id' field
      final corruptPlayers = allPlayers.where((p) => p['id'] == null).toList();

      debugPrint('Found ${corruptPlayers.length} corrupt player records');

      if (corruptPlayers.isEmpty) {
        setState(() {
          _isImporting = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Corrupt Players'),
              content: const Text(
                  'All player records have valid id fields. No action needed!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fix Corrupt Player Records?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${corruptPlayers.length} player records with missing id fields.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'These records were likely created by an earlier version of the utility. '
                  'They will be DELETED because they cannot be fixed (the original player ID is unknown).',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text('Examples:'),
                const SizedBox(height: 8),
                ...corruptPlayers.take(5).map((player) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${player['firstName'] ?? 'Unknown'} ${player['lastName'] ?? 'Unknown'} - Season ${player['seasonId'] ?? '?'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
                if (corruptPlayers.length > 5)
                  Text(
                    '... and ${corruptPlayers.length - 5} more',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'After deletion, run "Find & Create Missing Player Records" again to recreate them properly.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Corrupt Records'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      // Delete the corrupt player records
      int deleted = 0;
      int failed = 0;

      // Get the Firebase database key for each corrupt player and delete it
      final db = DatabaseService.instance;
      final allPlayerResults = await db.query('Players');

      for (var corruptPlayer in corruptPlayers) {
        try {
          // Find the Firebase key for this player record
          // We need to match by the exact data since we can't use id
          for (var result in allPlayerResults) {
            if (result['id'] == null &&
                result['firstName'] == corruptPlayer['firstName'] &&
                result['lastName'] == corruptPlayer['lastName'] &&
                result['seasonId'] == corruptPlayer['seasonId'] &&
                result['teamId'] == corruptPlayer['teamId']) {
              // Found the corrupt record - delete it
              final key = result[
                  '_key']; // Firebase push key (stored as '_key' by DatabaseService)
              if (key != null) {
                await db.delete('Players', key: key);
                deleted++;
                debugPrint(
                    'Deleted corrupt player: ${corruptPlayer['firstName']} ${corruptPlayer['lastName']} (season ${corruptPlayer['seasonId']}, key: $key)');
              } else {
                debugPrint(
                    'Warning: No _key found for corrupt player: ${corruptPlayer['firstName']} ${corruptPlayer['lastName']}');
              }
              break;
            }
          }
        } catch (e) {
          failed++;
          debugPrint('Failed to delete corrupt player: $e');
        }
      }

      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Corrupt Records Deleted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully deleted: $deleted corrupt records'),
                if (failed > 0)
                  Text(
                    'Failed: $failed records',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Next Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Click "Find & Create Missing Player Records" to recreate them properly',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2. The players will be created with correct id fields this time',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fix corrupt players: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
