# Data Import System Documentation

## Overview

The TeamSync data import system allows you to import Teams, Seasons, Players, Games, and Game Events from CSV files or specialized game statistics formats.

## Features

- **CSV Template Generation**: Download pre-formatted CSV templates for each entity type
- **Automatic Column Mapping**: Intelligently maps common column names to model fields
- **Entity Matching**: Fuzzy matching to link imported data with existing records
- **Validation**: Comprehensive validation before import with detailed error reporting
- **Batch Processing**: Processes imports in configurable batches to avoid rate limits
- **Error Recovery**: Skip-and-log approach - export failed rows for correction and re-import
- **Import Tracking**: All imports logged to `_imports` table with full audit trail
- **Import Flag**: All imported records marked with `isFromImport: true`

## Getting Started

### 1. Access the Import Page

Navigate to the Data Import page from your app menu.

### 2. Select Entity Type

Choose what type of data you're importing:
- **Team**: Team/club information
- **Season**: Season definitions
- **Player**: Player roster data
- **Game**: Game/match information
- **GameEvent**: Individual game events (goals, assists, etc.)

### 3. Download Template

Click "Download Template" to get a CSV file with:
- Proper column headers
- Column descriptions
- Example data row

### 4. Prepare Your Data

Fill in the template with your data, following the format and requirements shown.

## CSV Templates

### Team Template

**Required Columns:**
- `fullName`: Full team name
- `shortName`: Abbreviated team name

**Optional Columns:**
- `color1`: Primary color (hex #RRGGBB or ARGB integer)
- `color2`: Secondary color
- `logoUrl`: URL to team logo
- `clubId`: Parent club ID if applicable

**Example:**
```csv
fullName,shortName,color1,color2
Springfield Strikers,Strikers,#0000FF,#FFFFFF
```

### Season Template

**Required Columns:**
- `name`: Season name (e.g., "2024 Fall")
- `teamId`: Team ID this season belongs to

**Optional Columns:**
- `logoUrl`: Season-specific logo

**Example:**
```csv
name,teamId
2024 Fall,1
2024 Spring,1
```

### Player Template

**Required Columns:**
- `firstName`: Player first name
- `lastName`: Player last name
- `number`: Jersey number
- `teamId`: Team ID
- `seasonId`: Season ID

**Optional Columns:**
- `profileImage`: URL to profile photo
- `actionPhoto`: URL to action shot

**Example:**
```csv
firstName,lastName,number,teamId,seasonId
John,Smith,10,1,1
Jane,Doe,7,1,1
```

### Game Template

**Required Columns:**
- `seasonId`: Season ID
- `homeTeamId`: Home team ID
- `awayTeamId`: Away team ID
- `date`: Game date (ISO8601: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)

**Optional Columns:**
- `homeTeamScore`: Final home score
- `awayTeamScore`: Final away score
- `gameStatus`: Game status (0=Not Started, 9=Final)
- `description`: Game description
- `gameLinks`: URLs to highlights/stats

**Example:**
```csv
seasonId,homeTeamId,awayTeamId,date,homeTeamScore,awayTeamScore,gameStatus
1,1,2,2024-11-25T14:00:00,3,2,9
```

### GameEvent Template

**Required Columns:**
- `gameId`: Game ID
- `teamId`: Team ID
- `seasonId`: Season ID
- `eventType`: Event type (Shot, Assist, Save, PenaltyKick, Corner, Foul, Card, Offsides, Period)
- `eventMinute`: Minute of event
- `eventPeriod`: Period (1=1st Half, 2=2nd Half, etc.)
- `eventData`: Event-specific data (meaning varies by type)

**Optional Columns:**
- `playerId`: Player ID
- `eventUrls`: URLs to video/images

**Event Data Values:**

**Shot:**
- 0 = Goal
- 1 = Saved (on target)
- 2 = Hit post (off target)
- 3 = Off target
- 4 = Blocked (on target)

**Card:**
- 0 = Yellow card
- 1 = Second yellow
- 2 = Red card

**Example:**
```csv
gameId,teamId,seasonId,playerId,eventType,eventMinute,eventPeriod,eventData
1,1,1,10,Shot,23,1,0
1,1,1,7,Assist,23,1,0
```

## Game Statistics Import

For game statistics in the tab-delimited format (common from stat tracking software), use the specialized Game Stats Parser:

**Format Example:**
```
#   Athlete	AST	G	PTS	SHT	SOG	SOG%	S%	PKM	PKA	YC
1 Collin McBRIDE, SR	0	2	2	5	4	80.0%	40.0%	1	1	0
```

The parser will automatically:
- Extract player numbers and names
- Create Shot events for goals
- Create Assist events
- Create PenaltyKick events
- Create Card events for yellow/red cards
- Match players by name and number

## Import Process

### Validation Phase

1. **Column Detection**: System auto-detects column mappings
2. **Field Validation**: Checks required fields, data types, formats
3. **Referential Integrity**: Verifies foreign keys exist (teamId, seasonId, etc.)
4. **Entity Matching**: Attempts to match with existing records

### Import Phase

1. **Batch Processing**: Processes rows in batches (default: 50 rows)
2. **ID Generation**: Auto-generates IDs for new entities
3. **Skip on Error**: Invalid rows are skipped and logged
4. **Progress Tracking**: Real-time progress updates

### Post-Import

1. **Results Summary**: Shows success, error, and skip counts
2. **Error Export**: Download CSV with error details and suggested fixes
3. **Import Logging**: Record saved to `_imports` table

## Entity Matching

The system uses fuzzy matching to link imported data with existing records:

### Match Confidence Levels

- **Exact Match (≥95%)**: Automatically uses existing entity
- **Probable Match (70-94%)**: Flagged for user review
- **No Match (<70%)**: Creates new entity

### Matching Criteria

**Teams:**
- Full name similarity (Levenshtein distance)

**Players:**
- First + last name similarity
- Jersey number match (boosts confidence)
- Season context

**Seasons:**
- Name similarity
- Team ID match

## Error Handling

### Skip-and-Log Approach

When errors occur:
1. Row is skipped (not imported)
2. Error details recorded
3. Import continues with next row
4. All errors exported to CSV

### Error CSV Format

The error export includes:
- Row number
- Original data
- Error messages per field
- Suggested fixes

### Correcting and Re-importing

1. Download error CSV
2. Fix issues in indicated fields
3. Save corrected CSV
4. Re-import (only corrected rows)

## Import Flags

All imported entities include:
```dart
isFromImport: true
```

This distinguishes imported data from manually created records, useful for:
- Data provenance tracking
- Bulk operations
- Reporting and analytics

## Import History

All imports are logged to the `_imports` table with:
- Import ID (unique identifier)
- Timestamp
- User ID
- File name
- Entity type
- Row counts (total, success, error, skipped)
- Duration

## Best Practices

### Data Preparation

1. **Use Templates**: Always start with downloaded templates
2. **Validate Locally**: Check data in spreadsheet before upload
3. **Small Batches**: Test with small subset first
4. **Required Fields**: Ensure all required fields are populated
5. **Data Types**: Use correct formats (dates, numbers, etc.)

### Import Strategy

1. **Order Matters**: Import in dependency order:
   - Teams first
   - Seasons next
   - Players next
   - Games next
   - Game Events last

2. **Incremental**: Import one season at a time
3. **Validate First**: Use "Validate Only" before actual import
4. **Review Matches**: Check entity matches for accuracy
5. **Error Recovery**: Fix and re-import errors promptly

### Performance

- **Batch Size**: Default 50 rows, adjust based on complexity
- **Batch Delay**: 100ms between batches to avoid rate limits
- **Connection**: Stable internet connection recommended
- **Large Imports**: Split very large files (>1000 rows)

## Troubleshooting

### Common Issues

**"Team ID does not exist"**
- Import teams first, then reference their IDs

**"Invalid date format"**
- Use ISO8601: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`

**"Jersey number must be a number"**
- Remove any non-numeric characters

**"Column not recognized"**
- Check spelling, use template column names

**"Import failed: timeout"**
- Reduce batch size or split file

### Getting Help

For additional support:
1. Check error CSV for specific issues
2. Review validation messages
3. Verify data against templates
4. Test with template example data

## API Reference

### Services

**CsvParserService**
- Parses CSV files to ImportRow objects
- Auto-detects column mappings
- Handles various delimiters and formats

**EntityMatcherService**
- Fuzzy matches entities by name
- Returns confidence scores
- Supports Teams, Players, Seasons

**ImportValidatorService**
- Validates all required fields
- Checks referential integrity
- Returns detailed error messages

**DataImporterService**
- Orchestrates import process
- Batch processing with progress events
- Logs all imports to database

**ErrorCsvExporterService**
- Exports error rows to CSV
- Includes suggested fixes
- Generates import summaries

**CsvTemplateService**
- Generates blank templates
- Includes descriptions and examples
- Supports all entity types

**GameStatsParser**
- Parses tab-delimited game stats
- Extracts player information
- Generates GameEvent rows

## Examples

See `/import_examples` directory for sample files and formats.

