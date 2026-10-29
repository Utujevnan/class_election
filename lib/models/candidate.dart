import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Candidate {
  Candidate({this.id = '', required this.name, this.votes = 0});

  final String id;
  final String name;
  int votes;

  Map<String, dynamic> toMap() => {'name': name, 'votes': votes};

  factory Candidate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Candidate(
      id: doc.id,
      name: data['name'] as String,
      votes: (data['votes'] as num).toInt(),
    );
  }
}

CollectionReference<Map<String, dynamic>> myCandidates() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('candidates');
}

CollectionReference<Map<String, dynamic>> myVoters() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('voters');
}

Future<void> addSampleCandidates() async {
  final batch = FirebaseFirestore.instance.batch();
  for (final name in ['Keza', 'Mutoni', 'Jean']) {
    batch.set(myCandidates().doc(), Candidate(name: name).toMap());
  }
  await batch.commit();
}