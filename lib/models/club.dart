import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/config/database_collections.dart';
import 'package:team_sync/models/team.dart';

class Club extends Equatable {
  final int id;
  final String name;
  final String? description;
  final Color color1;
  final Color color2;
  final String? logoUrl;
  final DateTime createdAt;
  final String? createdBy; // User ID of creator (club admin)
  final List<String>? adminIds; // List of admin user IDs

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.color1 = Colors.blue,
    this.color2 = Colors.blueAccent,
    this.logoUrl,
    required this.createdAt,
    this.createdBy,
    this.adminIds,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color1: map['color1'] != null && map['color1'] != 0
          ? Color(map['color1'])
          : Colors.blue,
      color2: map['color2'] != null && map['color2'] != 0
          ? Color(map['color2'])
          : Colors.blueAccent,
      logoUrl: map['logoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'],
      adminIds:
          map['adminIds'] != null ? List<String>.from(map['adminIds']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color1': color1.toARGB32(),
      'color2': color2.toARGB32(),
      'logoUrl': logoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'adminIds': adminIds,
    };
  }

  static Future<Club?> fromId(int id) async {
    // Read directly from Firebase Clubs path (not subscription-based)
    final snapshot =
        await FirebaseDatabase.instance.ref('Clubs').child(id.toString()).get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return Club.fromMap(data);
    }
    return null;
  }

  static Future<List<Club>> all() async {
    // Read all clubs directly from Firebase
    final snapshot = await FirebaseDatabase.instance.ref('Clubs').get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final clubsMap = Map<String, dynamic>.from(snapshot.value as Map);
    return clubsMap.values
        .map((data) => Club.fromMap(Map<String, dynamic>.from(data as Map)))
        .toList(growable: false);
  }

  Future<List<Team>> getTeams() async {
    // Query teams directly from Firebase where clubId matches
    final snapshot = await FirebaseDatabase.instance
        .ref(ClubSyncCollections.teams)
        .orderByChild('clubId')
        .equalTo(id)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final teamsMap = Map<String, dynamic>.from(snapshot.value as Map);
    return teamsMap.values
        .map((data) => Team.fromMap(Map<String, dynamic>.from(data as Map)))
        .toList(growable: false);
  }

  Club copyWith({
    int? id,
    String? name,
    String? description,
    Color? color1,
    Color? color2,
    String? logoUrl,
    DateTime? createdAt,
    String? createdBy,
    List<String>? adminIds,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color1: color1 ?? this.color1,
      color2: color2 ?? this.color2,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      adminIds: adminIds ?? this.adminIds,
    );
  }

  /// Check if a user is an admin of this club
  bool isClubAdmin(String? userId) {
    if (userId == null) return false;
    if (createdBy == userId) return true;
    if (adminIds != null && adminIds!.contains(userId)) return true;
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color1,
        color2,
        logoUrl,
        createdAt,
        createdBy,
        adminIds,
      ];
}
