class Rescue {
  final int? id;
  final String message;
  final String locationText;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime timestamp;

  Rescue({
    this.id,
    required this.message,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'locationText': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Rescue.fromMap(Map<String, dynamic> map) {
    return Rescue(
      id: map['id'],
      message: map['message'],
      locationText: map['locationText'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}