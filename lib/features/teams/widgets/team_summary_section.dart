import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';

class TeamSummarySection extends StatelessWidget {
  final Team team;
  final VoidCallback? onSummaryChanged;

  const TeamSummarySection({
    super.key,
    required this.team,
    this.onSummaryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final summaryMessage = team.summary;
    final hasSummary = summaryMessage != null && summaryMessage.isNotEmpty;
    final isAdmin = team.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid);

    if (hasSummary) {
      return InkWell(
        onTap:
            !kIsWeb && isAdmin ? () => _showEditSummaryDialog(context) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                team.color1.withValues(alpha: 0.1),
                team.color2.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: team.color1.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: team.color1,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summaryMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!kIsWeb && isAdmin)
                Icon(
                  Icons.edit,
                  color: team.color1,
                  size: 18,
                ),
            ],
          ),
        ),
      );
    } else if (!kIsWeb && isAdmin) {
      return InkWell(
        onTap: () => _showEditSummaryDialog(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                team.color1.withValues(alpha: 0.05),
                team.color2.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: team.color1.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: team.color1,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.editTeamSummary,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: team.color1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showEditSummaryDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: team.summary ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.editTeamSummary),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: loc.teamSummaryHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      // Save to database
      try {
        await DatabaseService.instance.update(
          'Teams',
          {'summary': result.isEmpty ? null : result},
          key: team.id.toString(),
        );
        Team.clearCache();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.teamSummarySaved)),
          );

          // Trigger callback to refresh parent widget
          onSummaryChanged?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.errorSaving(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
