import '../models/candidate.dart';

List<Candidate> rankCandidates(List<Candidate> candidates) {
  final ranked = List<Candidate>.from(candidates);
  ranked.sort((a, b) => b.votes.compareTo(a.votes));
  return ranked;
}

int totalVotes(List<Candidate> candidates) {
  var total = 0;
  for (final candidate in candidates) {
    total += candidate.votes;
  }
  return total;
}

double share(int votes, int total) {
  if (total == 0) {
    return 0;
  }
  return votes / total;
}

String percentText(int votes, int total) {
  return '${(share(votes, total) * 100).toStringAsFixed(1)}%';
}

String voteWord(int count) {
  return count == 1 ? 'vote' : 'votes';
}

String bannerText(List<Candidate> candidates) {
  if (totalVotes(candidates) == 0) {
    return 'No votes yet';
  }
  var top = 0;
  for (final candidate in candidates) {
    if (candidate.votes > top) {
      top = candidate.votes;
    }
  }
  final leaders = candidates.where((c) => c.votes == top).toList();
  if (leaders.length == 1) {
    return 'Winner: ${leaders.first.name}';
  }
  final names = leaders.map((c) => c.name).toList();
  final joined =
      '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  return 'Tie between $joined ($top ${voteWord(top)} each)';
}