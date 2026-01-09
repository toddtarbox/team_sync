import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/widgets/game_result.dart'; // Assuming this is where GameResult is
import 'package:team_sync/widgets/common/tappable_image.dart'; // If needed for avatars or similar
import 'package:team_sync/l10n/app_localizations.dart';

class SeasonCalendarView extends StatefulWidget {
  final Season season;
  final List<Game> games;
  final Function(Game) onGameTap;

  const SeasonCalendarView({
    super.key,
    required this.season,
    required this.games,
    required this.onGameTap,
  });

  @override
  State<SeasonCalendarView> createState() => _SeasonCalendarViewState();
}

class _SeasonCalendarViewState extends State<SeasonCalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<Game>> _gamesByDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _groupGames();
  }

  void _groupGames() {
    _gamesByDay = {};
    for (var game in widget.games) {
      final date = DateTime(game.date.year, game.date.month, game.date.day);
      if (_gamesByDay[date] == null) {
        _gamesByDay[date] = [];
      }
      _gamesByDay[date]!.add(game);
    }
  }

  @override
  void didUpdateWidget(covariant SeasonCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.games != oldWidget.games) {
      _groupGames();
    }
  }

  List<Game> _getGamesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _gamesByDay[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedGames =
        _selectedDay != null ? _getGamesForDay(_selectedDay!) : [];

    return Column(
      children: [
        TableCalendar<Game>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getGamesForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ListView.builder(
            itemCount: selectedGames.length,
            itemBuilder: (context, index) {
              final game = selectedGames[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: ListTile(
                  onTap: () => widget.onGameTap(game),
                  title: Text(game.displayName(widget.season.teamId)),
                  subtitle: Text(DateFormat('h:mm a').format(game.date)),
                  trailing: GameResult(game, widget.season.teamId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
