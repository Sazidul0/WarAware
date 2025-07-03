class User {
  final String uid;
  final String uname;
  final String passwordHash; // Changed from password
  final String? imageUrl;
  final bool isAdmin;
  final String? occupation;
  final bool isVerified;

  User({
    required this.uid,
    required this.uname,
    required this.passwordHash, // Added this
    this.imageUrl,
    required this.isAdmin,
    this.occupation,
    required this.isVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'uname': uname,
      'passwordHash': passwordHash, // Added this
      'imageUrl': imageUrl,
      'isAdmin': isAdmin ? 1 : 0,
      'occupation': occupation,
      'isVerified': isVerified ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      uname: map['uname'],
      passwordHash: map['passwordHash'], // Added this
      imageUrl: map['imageUrl'],
      isAdmin: map['isAdmin'] == 1,
      occupation: map['occupation'],
      isVerified: map['isVerified'] == 1,
    );
  }
}