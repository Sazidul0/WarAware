enum PostStatus {
  Verified,
  Unverified,
  AIFlagged;

  // Helper to convert string from DB to Enum
  static PostStatus fromString(String status) {
    return PostStatus.values.firstWhere(
          (e) => e.name == status,
      orElse: () => PostStatus.Unverified,
    );
  }
}

enum ZoneType {
  Aid,
  Safe,
  Conflict;

  // Helper to convert string from DB to Enum
  static ZoneType fromString(String type) {
    return ZoneType.values.firstWhere(
          (e) => e.name == type,
      orElse: () => ZoneType.Conflict, // Default value
    );
  }
}
