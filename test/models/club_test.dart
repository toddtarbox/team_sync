import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/models/club.dart';

void main() {
  group('Club Model Tests', () {
    test('Club.fromMap creates club correctly', () {
      final map = {
        'id': 1,
        'name': 'Test Club',
        'description': 'A test club',
        'color1': Colors.blue.toARGB32(),
        'color2': Colors.blueAccent.toARGB32(),
        'logoUrl': 'https://example.com/logo.png',
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      };

      final club = Club.fromMap(map);

      expect(club.id, 1);
      expect(club.name, 'Test Club');
      expect(club.description, 'A test club');
      expect(club.logoUrl, 'https://example.com/logo.png');
      expect(club.createdAt, DateTime(2024, 1, 1));
    });

    test('Club.toMap converts club correctly', () {
      final club = Club(
        id: 1,
        name: 'Test Club',
        description: 'A test club',
        color1: Colors.blue,
        color2: Colors.blueAccent,
        logoUrl: 'https://example.com/logo.png',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = club.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test Club');
      expect(map['description'], 'A test club');
      expect(map['color1'], Colors.blue.toARGB32());
      expect(map['color2'], Colors.blueAccent.toARGB32());
      expect(map['logoUrl'], 'https://example.com/logo.png');
      expect(map['createdAt'], DateTime(2024, 1, 1).millisecondsSinceEpoch);
    });

    test('Club.copyWith creates new club with updated fields', () {
      final club = Club(
        id: 1,
        name: 'Test Club',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = club.copyWith(name: 'Updated Club');

      expect(updated.id, 1);
      expect(updated.name, 'Updated Club');
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });

    test('Club equality works correctly', () {
      final club1 = Club(
        id: 1,
        name: 'Test Club',
        createdAt: DateTime(2024, 1, 1),
      );

      final club2 = Club(
        id: 1,
        name: 'Test Club',
        createdAt: DateTime(2024, 1, 1),
      );

      final club3 = Club(
        id: 2,
        name: 'Different Club',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(club1, equals(club2));
      expect(club1, isNot(equals(club3)));
    });

    test('Club handles null description and logoUrl', () {
      final club = Club(
        id: 1,
        name: 'Test Club',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(club.description, isNull);
      expect(club.logoUrl, isNull);

      final map = club.toMap();
      expect(map['description'], isNull);
      expect(map['logoUrl'], isNull);
    });

    test('Club uses default colors when not provided in fromMap', () {
      final map = {
        'id': 1,
        'name': 'Test Club',
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      };

      final club = Club.fromMap(map);

      expect(club.color1, Colors.blue);
      expect(club.color2, Colors.blueAccent);
    });
  });
}
