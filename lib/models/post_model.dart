import '../utils/enum.dart';

class Post {
  final int? id; // Database primary key
  final String uid;
  final String uname;
  final DateTime time;
  final ZoneType zoneType; // Replaced 'Title' for clarity
  final String description;
  final String? imageUrl;
  final String? communityNotes;
  final PostStatus postStatus;
  final double verificationScore;
  final double latitude;
  final double longitude;

  Post({
    this.id,
    required this.uid,
    required this.uname,
    required this.time,
    required this.zoneType,
    required this.description,
    this.imageUrl,
    this.communityNotes,
    required this.postStatus,
    required this.verificationScore,
    required this.latitude,
    required this.longitude,
  });

  // Convert a Post object into a Map.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'uname': uname,
      'time': time.toIso8601String(), // Store as a string
      'zoneType': zoneType.name, // Store enum as string
      'description': description,
      'imageUrl': imageUrl,
      'communityNotes': communityNotes,
      'postStatus': postStatus.name, // Store enum as string
      'verificationScore': verificationScore,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create a Post object from a Map.
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      uid: map['uid'],
      uname: map['uname'],
      time: DateTime.parse(map['time']),
      zoneType: ZoneType.fromString(map['zoneType']),
      description: map['description'],
      imageUrl: map['imageUrl'],
      communityNotes: map['communityNotes'],
      postStatus: PostStatus.fromString(map['postStatus']),
      verificationScore: map['verificationScore'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}