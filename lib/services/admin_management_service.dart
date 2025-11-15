import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:team_sync/config/database_collections.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/admin_service.dart';

/// Service for managing club and team admins
class AdminManagementService {
  static final AdminManagementService instance =
      AdminManagementService._internal();

  AdminManagementService._internal();

  /// Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  // ============================================
  // CLUB ADMIN MANAGEMENT
  // ============================================

  /// Check if current user can manage club admins
  bool canManageClubAdmins(Club club) {
    // System admin can manage any club
    if (AdminService.instance.isAdmin) return true;

    // Club creator can manage admins
    if (club.createdBy == currentUserId) return true;

    // Club admins can manage other admins
    if (club.isClubAdmin(currentUserId)) return true;

    return false;
  }

  /// Add a club admin by email
  Future<bool> addClubAdmin(Club club, String adminEmail) async {
    if (!canManageClubAdmins(club)) {
      throw Exception('You do not have permission to manage club admins');
    }

    // In a real app, you'd look up the user ID by email
    // For now, we'll use email as placeholder
    // TODO: Implement user lookup service
    final adminUserId = adminEmail; // Placeholder - should be actual UID

    final currentAdminIds = club.adminIds ?? [];
    if (currentAdminIds.contains(adminUserId)) {
      return false; // Already an admin
    }

    final updatedAdminIds = [...currentAdminIds, adminUserId];

    await FirebaseDatabase.instance
        .ref('Clubs')
        .child(club.id.toString())
        .update({'adminIds': updatedAdminIds});

    return true;
  }

  /// Remove a club admin
  Future<bool> removeClubAdmin(Club club, String adminUserId) async {
    if (!canManageClubAdmins(club)) {
      throw Exception('You do not have permission to manage club admins');
    }

    // Cannot remove the creator
    if (club.createdBy == adminUserId) {
      throw Exception('Cannot remove the club creator');
    }

    final currentAdminIds = club.adminIds ?? [];
    if (!currentAdminIds.contains(adminUserId)) {
      return false; // Not an admin
    }

    final updatedAdminIds =
        currentAdminIds.where((id) => id != adminUserId).toList();

    await FirebaseDatabase.instance
        .ref('Clubs')
        .child(club.id.toString())
        .update({'adminIds': updatedAdminIds});

    return true;
  }

  /// Get list of club admins with details
  Future<List<Map<String, String>>> getClubAdmins(Club club) async {
    final adminIds = club.adminIds ?? [];
    final admins = <Map<String, String>>[];

    // Add creator
    if (club.createdBy != null) {
      admins.add({
        'id': club.createdBy!,
        'email': await _getUserEmail(club.createdBy!),
        'role': 'Creator',
      });
    }

    // Add other admins
    for (final adminId in adminIds) {
      if (adminId != club.createdBy) {
        admins.add({
          'id': adminId,
          'email': await _getUserEmail(adminId),
          'role': 'Admin',
        });
      }
    }

    return admins;
  }

  // ============================================
  // TEAM ADMIN MANAGEMENT
  // ============================================

  /// Check if current user can manage team admins
  bool canManageTeamAdmins(Team team, Club? club) {
    // System admin can manage any team
    if (AdminService.instance.isAdmin) return true;

    // Club admin can manage teams in their club
    if (club != null && club.isClubAdmin(currentUserId)) return true;

    // Team creator can manage admins
    if (team.createdBy == currentUserId) return true;

    // Team admins can manage other admins
    if (team.isTeamAdmin(currentUserId)) return true;

    return false;
  }

  /// Add a team admin by email
  Future<bool> addTeamAdmin(Team team, String adminEmail, {Club? club}) async {
    if (!canManageTeamAdmins(team, club)) {
      throw Exception('You do not have permission to manage team admins');
    }

    // In a real app, you'd look up the user ID by email
    final adminUserId = adminEmail; // Placeholder - should be actual UID

    final currentAdminIds = team.adminIds ?? [];
    if (currentAdminIds.contains(adminUserId)) {
      return false; // Already an admin
    }

    final updatedAdminIds = [...currentAdminIds, adminUserId];

    await FirebaseDatabase.instance
        .ref('Teams')
        .child(team.id.toString())
        .update({'adminIds': updatedAdminIds});

    return true;
  }

  /// Remove a team admin
  Future<bool> removeTeamAdmin(Team team, String adminUserId,
      {Club? club}) async {
    if (!canManageTeamAdmins(team, club)) {
      throw Exception('You do not have permission to manage team admins');
    }

    // Cannot remove the creator
    if (team.createdBy == adminUserId) {
      throw Exception('Cannot remove the team creator');
    }

    final currentAdminIds = team.adminIds ?? [];
    if (!currentAdminIds.contains(adminUserId)) {
      return false; // Not an admin
    }

    final updatedAdminIds =
        currentAdminIds.where((id) => id != adminUserId).toList();

    await FirebaseDatabase.instance
        .ref(ClubSyncCollections.teams)
        .child(team.id.toString())
        .update({'adminIds': updatedAdminIds});

    return true;
  }

  /// Get list of team admins with details
  Future<List<Map<String, String>>> getTeamAdmins(Team team) async {
    final adminIds = team.adminIds ?? [];
    final admins = <Map<String, String>>[];

    // Add creator
    if (team.createdBy != null) {
      admins.add({
        'id': team.createdBy!,
        'email': await _getUserEmail(team.createdBy!),
        'role': 'Creator',
      });
    }

    // Add other admins
    for (final adminId in adminIds) {
      if (adminId != team.createdBy) {
        admins.add({
          'id': adminId,
          'email': await _getUserEmail(adminId),
          'role': 'Admin',
        });
      }
    }

    return admins;
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get user email by ID (placeholder implementation)
  Future<String> _getUserEmail(String userId) async {
    // TODO: Implement proper user lookup
    // For now, return the userId as email placeholder
    // In production, you'd query a users collection or use Firebase Auth Admin
    return userId;
  }
}
