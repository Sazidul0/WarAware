import '../utils/enum.dart';

class Zone {
  final int? id; // Database primary key
  final ZoneType type;
  final String description;
  final String userId;
  final int postId;

  Zone({
    this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.postId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'userId': userId,
      'postId': postId,
    };
  }

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      id: map['id'],
      type: ZoneType.fromString(map['type']),
      description: map['description'],
      userId: map['userId'],
      postId: map['postId'],
    );
  }
}