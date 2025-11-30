import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/date_parser.dart';

class ImportValidatorService {
  /// Validate a single import row
  Future<List<ValidationError>> validateRow(
    ImportRow row,
  ) async {
    switch (row.entityType) {
      case 'Team':
        return _validateTeam(row.data);
      case 'Season':
        return await _validateSeason(row.data);
      case 'Player':
        return await _validatePlayer(row.data);
      case 'Game':
        return await _validateGame(row.data);
      case 'GameEvent':
        return await _validateGameEvent(row.data);
      default:
        return [
          ValidationError(
            field: 'entityType',
            message: 'Unknown entity type: ${row.entityType}',
          ),
        ];
    }
  }

  List<ValidationError> _validateTeam(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    // Required fields
    if (data['fullName'] == null || data['fullName'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'fullName',
        message: 'Team full name is required',
      ));
    }

    if (data['shortName'] == null || data['shortName'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'shortName',
        message: 'Team short name is required',
      ));
    }

    // Optional color validation
    if (data['color1'] != null) {
      final color = _parseColor(data['color1']);
      if (color == null) {
        errors.add(const ValidationError(
          field: 'color1',
          message: 'Invalid color format',
          suggestedFix: 'Use hex format: #RRGGBB or ARGB integer',
        ));
      }
    }

    return errors;
  }

  Future<List<ValidationError>> _validateSeason(
      Map<String, dynamic> data) async {
    final errors = <ValidationError>[];

    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'name',
        message: 'Season name is required',
      ));
    }

    if (data['teamId'] == null) {
      errors.add(const ValidationError(
        field: 'teamId',
        message: 'Team ID is required',
      ));
    } else if (data['teamId'] is! int &&
        int.tryParse(data['teamId'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'teamId',
        message: 'Team ID must be a number',
      ));
    } else {
      // Validate team exists
      try {
        final teamId = data['teamId'] is int
            ? data['teamId']
            : int.parse(data['teamId'].toString());
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'teamId',
            message: 'Team ID $teamId does not exist',
          ));
        }

        // Check for duplicate season name for this team
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          final seasonName = data['name'].toString();
          final allSeasons = await DatabaseService.instance.query(
            'Seasons',
            orderByChild: 'teamId',
            equalTo: teamId,
          );

          final duplicate = allSeasons.any((season) =>
              season['name'].toString().toLowerCase() ==
              seasonName.toLowerCase());

          if (duplicate) {
            errors.add(ValidationError(
              field: 'name',
              message:
                  'A season with name "$seasonName" already exists for this team',
              suggestedFix:
                  'Use a different season name or update the existing season',
            ));
          }
        }
      } catch (e) {
        debugPrint('Error validating season: $e');
      }
    }

    return errors;
  }

  Future<List<ValidationError>> _validatePlayer(
      Map<String, dynamic> data) async {
    final errors = <ValidationError>[];

    if (data['firstName'] == null || data['firstName'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'firstName',
        message: 'Player first name is required',
      ));
    }

    if (data['lastName'] == null || data['lastName'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'lastName',
        message: 'Player last name is required',
      ));
    }

    if (data['number'] == null) {
      errors.add(const ValidationError(
        field: 'number',
        message: 'Jersey number is required',
      ));
    } else if (data['number'] is! int &&
        int.tryParse(data['number'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'number',
        message: 'Jersey number must be a number',
      ));
    }

    if (data['teamId'] == null) {
      errors.add(const ValidationError(
        field: 'teamId',
        message: 'Team ID is required',
      ));
    } else {
      // Validate team exists
      try {
        final teamId = data['teamId'] is int
            ? data['teamId']
            : int.parse(data['teamId'].toString());
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'teamId',
            message: 'Team ID $teamId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating teamId: $e');
      }
    }

    if (data['seasonId'] == null) {
      errors.add(const ValidationError(
        field: 'seasonId',
        message: 'Season ID is required',
      ));
    } else {
      // Validate season exists
      try {
        final seasonId = data['seasonId'] is int
            ? data['seasonId']
            : int.parse(data['seasonId'].toString());
        final results = await DatabaseService.instance.query(
          'Seasons',
          orderByChild: 'id',
          equalTo: seasonId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'seasonId',
            message: 'Season ID $seasonId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating seasonId: $e');
      }
    }

    return errors;
  }

  Future<List<ValidationError>> _validateGame(Map<String, dynamic> data) async {
    final errors = <ValidationError>[];

    if (data['seasonId'] == null) {
      errors.add(const ValidationError(
        field: 'seasonId',
        message: 'Season ID is required',
      ));
    } else {
      try {
        final seasonId = data['seasonId'] is int
            ? data['seasonId']
            : int.parse(data['seasonId'].toString());
        final results = await DatabaseService.instance.query(
          'Seasons',
          orderByChild: 'id',
          equalTo: seasonId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'seasonId',
            message: 'Season ID $seasonId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating seasonId: $e');
      }
    }

    if (data['homeTeamId'] == null) {
      errors.add(const ValidationError(
        field: 'homeTeamId',
        message: 'Home team ID is required',
      ));
    } else {
      try {
        final teamId = data['homeTeamId'] is int
            ? data['homeTeamId']
            : int.parse(data['homeTeamId'].toString());
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'homeTeamId',
            message: 'Home team ID $teamId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating homeTeamId: $e');
      }
    }

    if (data['awayTeamId'] == null) {
      errors.add(const ValidationError(
        field: 'awayTeamId',
        message: 'Away team ID is required',
      ));
    } else {
      try {
        final teamId = data['awayTeamId'] is int
            ? data['awayTeamId']
            : int.parse(data['awayTeamId'].toString());
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'awayTeamId',
            message: 'Away team ID $teamId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating awayTeamId: $e');
      }
    }

    if (data['date'] == null) {
      errors.add(const ValidationError(
        field: 'date',
        message: 'Game date is required',
      ));
    } else {
      final date = DateParser.parse(data['date'].toString());
      if (date == null) {
        errors.add(const ValidationError(
          field: 'date',
          message: 'Invalid date format',
          suggestedFix: 'Use formats: YYYY-MM-DD, MM/DD/YYYY, or MM.DD.YYYY',
        ));
      }
    }

    // Validate scores if present
    if (data['homeTeamScore'] != null &&
        data['homeTeamScore'] is! int &&
        int.tryParse(data['homeTeamScore'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'homeTeamScore',
        message: 'Home team score must be a number',
      ));
    }

    if (data['awayTeamScore'] != null &&
        data['awayTeamScore'] is! int &&
        int.tryParse(data['awayTeamScore'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'awayTeamScore',
        message: 'Away team score must be a number',
      ));
    }

    return errors;
  }

  Future<List<ValidationError>> _validateGameEvent(
      Map<String, dynamic> data) async {
    final errors = <ValidationError>[];

    if (data['gameId'] == null) {
      errors.add(const ValidationError(
        field: 'gameId',
        message: 'Game ID is required',
      ));
    } else {
      try {
        final gameId = data['gameId'] is int
            ? data['gameId']
            : int.parse(data['gameId'].toString());
        final results = await DatabaseService.instance.query(
          'Games',
          orderByChild: 'id',
          equalTo: gameId,
        );
        if (results.isEmpty) {
          errors.add(ValidationError(
            field: 'gameId',
            message: 'Game ID $gameId does not exist',
          ));
        }
      } catch (e) {
        debugPrint('Error validating gameId: $e');
      }
    }

    if (data['teamId'] == null) {
      errors.add(const ValidationError(
        field: 'teamId',
        message: 'Team ID is required',
      ));
    }

    if (data['seasonId'] == null) {
      errors.add(const ValidationError(
        field: 'seasonId',
        message: 'Season ID is required',
      ));
    }

    if (data['eventType'] == null || data['eventType'].toString().isEmpty) {
      errors.add(const ValidationError(
        field: 'eventType',
        message: 'Event type is required',
        suggestedFix:
            'Valid types: Shot, Assist, Save, PenaltyKick, Corner, Foul, Card, Offsides, Period',
      ));
    } else {
      final validTypes = [
        'Shot',
        'Assist',
        'Save',
        'PenaltyKick',
        'Corner',
        'Foul',
        'Card',
        'Offsides',
        'Period'
      ];
      if (!validTypes.contains(data['eventType'].toString())) {
        errors.add(ValidationError(
          field: 'eventType',
          message: 'Invalid event type: ${data['eventType']}',
          suggestedFix: 'Valid types: ${validTypes.join(", ")}',
        ));
      }
    }

    if (data['eventMinute'] == null) {
      errors.add(const ValidationError(
        field: 'eventMinute',
        message: 'Event minute is required',
      ));
    } else if (data['eventMinute'] is! int &&
        int.tryParse(data['eventMinute'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'eventMinute',
        message: 'Event minute must be a number',
      ));
    }

    if (data['eventPeriod'] == null) {
      errors.add(const ValidationError(
        field: 'eventPeriod',
        message: 'Event period is required',
      ));
    } else if (data['eventPeriod'] is! int &&
        int.tryParse(data['eventPeriod'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'eventPeriod',
        message: 'Event period must be a number',
      ));
    }

    if (data['eventData'] == null) {
      errors.add(const ValidationError(
        field: 'eventData',
        message: 'Event data is required',
      ));
    } else if (data['eventData'] is! int &&
        int.tryParse(data['eventData'].toString()) == null) {
      errors.add(const ValidationError(
        field: 'eventData',
        message: 'Event data must be a number',
      ));
    }

    return errors;
  }

  int? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    final str = value.toString().trim();
    if (str.startsWith('#')) {
      return int.tryParse(str.substring(1), radix: 16);
    }
    return int.tryParse(str);
  }
}
