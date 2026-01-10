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
    if (widget.games.isNotEmpty) {
      final firstGame =
          widget.games.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      _focusedDay = firstGame.date;
    } else {
      _focusedDay = DateTime.now();
    }
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
      if (oldWidget.games.isEmpty && widget.games.isNotEmpty) {
        final firstGame =
            widget.games.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
        setState(() {
          _focusedDay = firstGame.date;
          _selectedDay = _focusedDay;
        });
      }
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
          startingDayOfWeek: StartingDayOfWeek.sunday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            final gamesInMonth = widget.games
                .where((g) =>
                    g.date.year == focusedDay.year &&
                    g.date.month == focusedDay.month)
                .toList();

            setState(() {
              _focusedDay = focusedDay;
              if (gamesInMonth.isNotEmpty) {
                gamesInMonth.sort((a, b) => a.date.compareTo(b.date));
                _selectedDay = gamesInMonth.first.date;
              } else {
                _selectedDay = null;
              }
            });
          },
        ),
        const SizedBox(height: 8.0),
        if (_selectedDay != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('E, MMM d').format(_selectedDay!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
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
