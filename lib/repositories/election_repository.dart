import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/candidate.dart';

class ElectionRepository {
  ElectionRepository(this.uid);

  final String uid;

  CollectionReference<Map<String, dynamic>> get _candidates =>
      FirebaseFirestore.instance.collection('candidates');

  DocumentReference<Map<String, dynamic>> get _myVote =>
      FirebaseFirestore.instance.collection('voters').doc(uid);

  Stream<List<Candidate>> watchCandidates() => _candidates.snapshots().map(
    (snapshot) => snapshot.docs.map(Candidate.fromDoc).toList(),
  );

  Stream<bool> watchHasVoted() => _myVote.snapshots().map((doc) => doc.exists);

  Future<void> addCandidate(Candidate candidate) =>
      _candidates.add(candidate.toMap());

  Future<void> updateCandidate(String id, String name) =>
      _candidates.doc(id).update({'name': name});

  Future<void> deleteCandidate(String id) => _candidates.doc(id).delete();

  Future<void> vote({
    required String candidateId,
    required String voterName,
  }) async {
    final candidateRef = _candidates.doc(candidateId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final voterSnapshot = await transaction.get(_myVote);
      if (voterSnapshot.exists) throw StateError('already-voted');

      final candidateSnapshot = await transaction.get(candidateRef);
      if (!candidateSnapshot.exists) throw StateError('candidate-not-found');

      final currentVotes =
          (candidateSnapshot.data()?['votes'] as num?)?.toInt() ?? 0;
      transaction.set(_myVote, {'name': voterName, 'candidateId': candidateId});
      transaction.update(candidateRef, {'votes': currentVotes + 1});
    });
  }
}
