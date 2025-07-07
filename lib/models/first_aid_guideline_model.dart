class FirstAidGuideline {
  final int? id;
  final String problemName;
  final String problemDescription;

  FirstAidGuideline({
    this.id,
    required this.problemName,
    required this.problemDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'problemName': problemName,
      'problemDescription': problemDescription,
    };
  }

  factory FirstAidGuideline.fromMap(Map<String, dynamic> map) {
    return FirstAidGuideline(
      id: map['id'],
      problemName: map['problemName'],
      problemDescription: map['problemDescription'],
    );
  }
}