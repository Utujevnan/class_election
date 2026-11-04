import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/candidate.dart';
import '../repositories/election_repository.dart';

class ElectionState extends ChangeNotifier {
  ElectionState(this._repository) {
    debugPrint('Election state born for ${_repository.uid}');
    _listen();
  }

  void _listen() {
    _candidateSubscription = _repository.watchCandidates().listen((candidates) {
      _candidates = candidates;
      _candidatesLoaded = true;
      _candidateError = null;
      _notifyIfReady();
    }, onError: (Object error) => _setCandidateError(error));
    _voteSubscription = _repository.watchHasVoted().listen((hasVoted) {
      _hasVoted = hasVoted;
      _voteStatusLoaded = true;
      _voteError = null;
      _notifyIfReady();
    }, onError: (Object error) => _setVoteError(error));
  }

  final ElectionRepository _repository;
  StreamSubscription<List<Candidate>>? _candidateSubscription;
  StreamSubscription<bool>? _voteSubscription;

  List<Candidate> _candidates = [];
  bool _candidatesLoaded = false;
  bool _voteStatusLoaded = false;
  bool _hasVoted = false;
  String? _candidateError;
  String? _voteError;
  String _filter = 'all';

  List<Candidate> get candidates => List.unmodifiable(_candidates);
  bool get loading => !_candidatesLoaded || !_voteStatusLoaded;
  bool get hasVoted => _hasVoted;
  String? get error => _candidateError ?? _voteError;
  String get filter => _filter;

  List<Candidate> get visibleCandidates {
    switch (_filter) {
      case 'with_votes':
        return _candidates.where((candidate) => candidate.votes > 0).toList();
      case 'without_votes':
        return _candidates.where((candidate) => candidate.votes == 0).toList();
      default:
        return _candidates;
    }
  }

  List<Candidate> get rankedCandidates {
    final ranked = List<Candidate>.of(_candidates);
    ranked.sort((a, b) => b.votes.compareTo(a.votes));
    return ranked;
  }

  int get totalVotes =>
      _candidates.fold<int>(0, (total, candidate) => total + candidate.votes);

  String get winnerBanner {
    if (totalVotes == 0) return 'No votes yet';
    final topVotes = rankedCandidates.first.votes;
    final leaders = _candidates
        .where((candidate) => candidate.votes == topVotes)
        .toList();
    if (leaders.length == 1) return 'Winner: ${leaders.single.name}';
    final names = leaders.map((candidate) => candidate.name).toList();
    final joined =
        '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    return 'Tie between $joined ($topVotes ${topVotes == 1 ? 'vote' : 'votes'} each)';
  }

  double voteShare(Candidate candidate) =>
      totalVotes == 0 ? 0 : candidate.votes / totalVotes;

  String votePercent(Candidate candidate) =>
      '${(voteShare(candidate) * 100).toStringAsFixed(1)}%';

  void setFilter(String value) {
    if (!{'all', 'with_votes', 'without_votes'}.contains(value) ||
        value == _filter) {
      return;
    }
    _filter = value;
    notifyListeners();
  }

  void retry() {
    _candidateSubscription?.cancel();
    _voteSubscription?.cancel();
    _candidatesLoaded = false;
    _voteStatusLoaded = false;
    _candidateError = null;
    _voteError = null;
    notifyListeners();
    _listen();
  }

  Future<void> addCandidate(String name) =>
      _repository.addCandidate(Candidate(name: name));

  Future<void> editCandidate(String id, String name) =>
      _repository.updateCandidate(id, name);

  Future<void> removeCandidate(Candidate candidate) =>
      _repository.deleteCandidate(candidate.id);

  Future<void> vote(Candidate candidate, String voterName) =>
      _repository.vote(candidateId: candidate.id, voterName: voterName);

  void _notifyIfReady() {
    if (!loading) notifyListeners();
  }

  void _setCandidateError(Object error) {
    _candidateError = error.toString();
    _candidatesLoaded = true;
    notifyListeners();
  }

  void _setVoteError(Object error) {
    _voteError = error.toString();
    _voteStatusLoaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('Election state disposed: streams closed');
    _candidateSubscription?.cancel();
    _voteSubscription?.cancel();
    super.dispose();
  }
}
