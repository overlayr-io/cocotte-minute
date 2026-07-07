import 'package:equatable/equatable.dart';

import '../../tags/domain/tag.dart';

/// Un membre de la famille : prénom (requis), nom (optionnel), avatar (optionnel)
/// et ses tags associés.
class Person extends Equatable {
  const Person({
    required this.id,
    required this.firstName,
    this.lastName,
    this.avatarUrl,
    this.tags = const [],
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;
  final List<Tag> tags;

  /// Prénom + nom si le nom est renseigné, sinon le prénom seul.
  String get displayName =>
      (lastName == null || lastName!.isEmpty) ? firstName : '$firstName $lastName';

  bool hasTag(String tagId) => tags.any((t) => t.id == tagId);

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Tag.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, avatarUrl, tags];
}
