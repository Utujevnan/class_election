class Candidate {
  Candidate({required this.name, this.votes = 0});

  final String name;
  int votes;

  Map<String, dynamic> toJson() => {'name': name, 'votes': votes};

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        name: json['name'] as String,
        votes: (json['votes'] as num).toInt(),
      );
}
