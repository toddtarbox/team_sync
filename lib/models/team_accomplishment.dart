import 'package:team_sync/services/database_service.dart';

/// Team-wide accomplishment or recognition (not tied to a specific season)
/// Examples: Overall record, championships won, hall of fame, team milestones
class TeamAccomplishment {
  final int id;
  final int teamId;
  final String title;
  final String? description;
  final String?
      imageUrl; // Legacy single image URL - kept for backward compatibility
  final List<String> imageUrls; // New: multiple image URLs
  final String? url;
  final int? year; // Optional year for chronological ordering
  final int displayOrder; // For custom ordering

  TeamAccomplishment({
    required this.id,
    required this.teamId,
    required this.title,
    this.description,
    this.imageUrl,
    List<String>? imageUrls,
    this.url,
    this.year,
    this.displayOrder = 0,
  }) : imageUrls = imageUrls ?? [];

  factory TeamAccomplishment.fromMap(Map<String, dynamic> map) {
    // Handle backward compatibility: if imageUrls doesn't exist but imageUrl does, use it
    List<String> imageUrlsList = [];
    if (map['imageUrls'] != null) {
      imageUrlsList = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null &&
        (map['imageUrl'] as String).isNotEmpty) {
      imageUrlsList = [map['imageUrl']];
    }

    return TeamAccomplishment(
      id: map['id'],
      teamId: map['teamId'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'], // Keep for backward compatibility
      imageUrls: imageUrlsList,
      url: map['url'],
      year: map['year'],
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'title': title,
      'description': description,
      'imageUrl': imageUrls.isNotEmpty
          ? imageUrls[0]
          : imageUrl, // Store first image as legacy field
      'imageUrls': imageUrls,
      'url': url,
      'year': year,
      'displayOrder': displayOrder,
    };
  }

  /// Get the primary image URL (first in list or legacy imageUrl)
  String? get primaryImageUrl {
    if (imageUrls.isNotEmpty) return imageUrls[0];
    return imageUrl;
  }

  /// Check if this accomplishment has any images
  bool get hasImages =>
      imageUrls.isNotEmpty || (imageUrl != null && imageUrl!.isNotEmpty);

  /// Get all image URLs (combining new and legacy)
  List<String> get allImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  static Future<List<TeamAccomplishment>> listFromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('TeamAccomplishments', orderByChild: 'teamId', equalTo: teamId);
    final accomplishments =
        results.map((a) => TeamAccomplishment.fromMap(a)).toList();

    // Sort by display order, then by year (most recent first), then by title
    accomplishments.sort((a, b) {
      // First sort by display order
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;

      // Then by year (most recent first)
      if (a.year != null && b.year != null) {
        final yearCompare = b.year!.compareTo(a.year!);
        if (yearCompare != 0) return yearCompare;
      } else if (a.year != null) {
        return -1; // Items with years come first
      } else if (b.year != null) {
        return 1;
      }

      // Finally by title
      return a.title.compareTo(b.title);
    });

    return accomplishments;
  }

  Future<void> save() async {
    await DatabaseService.instance.insert(
      'TeamAccomplishments',
      toMap(),
      key: id.toString(),
    );
  }

  Future<void> delete() async {
    await DatabaseService.instance.delete(
      'TeamAccomplishments',
      key: id.toString(),
    );
  }

  /// Get a display string for the year (if available)
  String get yearDisplay => year != null ? year.toString() : '';

  /// Get a formatted display title with year if available
  String get displayTitle => year != null ? '$title ($year)' : title;
}
