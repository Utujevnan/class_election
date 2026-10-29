import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../utils/names.dart';
import '../utils/weather.dart';
import 'results_screen.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final _voterController = TextEditingController();
  final _candidateController = TextEditingController();
  bool _working = false;

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _vote(Candidate candidate) async {
    final voter = cleanName(_voterController.text);
    if (voter.isEmpty) {
      _message('Please type your name before voting.');
      return;
    }

    setState(() => _working = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final voterRef = myVoters().doc(voter.toLowerCase());
        final candidateRef = myCandidates().doc(candidate.id);
        final voterSnapshot = await transaction.get(voterRef);
        if (voterSnapshot.exists) throw StateError('already-voted');
        final candidateSnapshot = await transaction.get(candidateRef);
        final votes = (candidateSnapshot.data()?['votes'] as num?)?.toInt() ?? 0;
        transaction.set(voterRef, {'name': voter});
        transaction.update(candidateRef, {'votes': votes + 1});
      });
      _voterController.clear();
      _message('Thank you $voter. Your vote for ${candidate.name} is counted.');
    } on StateError {
      _message('$voter has already voted.');
    } catch (_) {
      _message('Could not submit your vote. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _addCandidate() async {
    final name = cleanName(_candidateController.text);
    if (name.isEmpty) return;
    setState(() => _working = true);
    try {
      await myCandidates().add(Candidate(name: name).toMap());
      _candidateController.clear();
    } catch (_) {
      _message('Could not add the candidate. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _removeCandidate(Candidate candidate) async {
    try {
      await myCandidates().doc(candidate.id).delete();
    } catch (_) {
      _message('Could not remove the candidate. Please try again.');
    }
  }

  void _openResults(List<Candidate> candidates) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(candidates: candidates)),
    );
  }

  @override
  void dispose() {
    _voterController.dispose();
    _candidateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: myCandidates().snapshots(),
      builder: (context, snapshot) {
        final candidates = snapshot.data?.docs
                .map((doc) => Candidate.fromDoc(doc))
                .toList() ??
            <Candidate>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Class Election'),
            actions: [
              IconButton(
                onPressed: () => _openResults(candidates),
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Results',
              ),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
              ),
            ],
          ),
          body: snapshot.hasError
              ? const Center(child: Text('Could not load candidates. Check your connection.'))
              : snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const KigaliWeatherCard(),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _voterController,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _candidateController,
                              decoration: const InputDecoration(
                                labelText: 'Add a candidate',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addCandidate(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _working ? null : _addCandidate,
                            icon: const Icon(Icons.add),
                            tooltip: 'Add candidate',
                          ),
                        ]),
                        const SizedBox(height: 8),
                        if (candidates.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No candidates yet. Add one above.'),
                            ),
                          ),
                        ...candidates.map((candidate) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.how_to_vote),
                                title: Text(candidate.name),
                                subtitle: Text(
                                  '${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'}',
                                ),
                                trailing: Wrap(spacing: 4, children: [
                                  IconButton(
                                    onPressed: () => _removeCandidate(candidate),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete candidate',
                                  ),
                                  FilledButton(
                                    onPressed: _working ? null : () => _vote(candidate),
                                    child: const Text('Vote'),
                                  ),
                                ]),
                              ),
                            )),
                      ],
                    ),
        );
      },
    );
  }
}

class KigaliWeatherCard extends StatefulWidget {
  const KigaliWeatherCard({super.key});

  @override
  State<KigaliWeatherCard> createState() => _KigaliWeatherCardState();
}

class _KigaliWeatherCardState extends State<KigaliWeatherCard> {
  late Future<Weather> _weather;

  @override
  void initState() {
    super.initState();
    _weather = fetchKigaliWeather();
  }

  void _retry() => setState(() => _weather = fetchKigaliWeather());

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Weather>(
          future: _weather,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Loading Kigali weather…'),
              ]);
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Row(children: [
                const Expanded(child: Text('Could not load Kigali weather. Check your internet.')),
                TextButton(onPressed: _retry, child: const Text('Retry')),
              ]);
            }
            final current = snapshot.data!;
            return Row(children: [
              const Icon(Icons.wb_cloudy_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kigali weather · ${current.temperature.round()}°C\n'
                  '${current.description}, humidity ${current.humidity}%',
                ),
              ),
              IconButton(onPressed: _retry, icon: const Icon(Icons.refresh), tooltip: 'Refresh weather'),
            ]);
          },
        ),
      ),
    );
  }
}
