import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _candidatesKey = 'class_election.candidates';
  static const _votersKey = 'class_election.voters';

  List<Candidate> candidates = [];
  List<String> voters = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController candidateController = TextEditingController();
  bool loading = true;

  int get totalVotes => voters.length;

  @override
  void initState() {
    super.initState();
    loadElection();
  }

  Future<void> loadElection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCandidates = prefs.getString(_candidatesKey);
    final savedVoters = prefs.getString(_votersKey);
    final loadedCandidates = savedCandidates == null
        ? [Candidate(name: 'Keza'), Candidate(name: 'Mutoni'), Candidate(name: 'Jean')]
        : (jsonDecode(savedCandidates) as List)
            .map((item) => Candidate.fromJson(item as Map<String, dynamic>))
            .toList();
    final loadedVoters = savedVoters == null
        ? <String>[]
        : (jsonDecode(savedVoters) as List).cast<String>();
    if (!mounted) return;
    setState(() {
      candidates = loadedCandidates;
      voters = loadedVoters;
      loading = false;
    });
    if (savedCandidates == null || savedVoters == null) await saveElection();
  }

  Future<void> saveElection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _candidatesKey,
      jsonEncode(candidates.map((candidate) => candidate.toJson()).toList()),
    );
    await prefs.setString(_votersKey, jsonEncode(voters));
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> vote(Candidate candidate) async {
    final voter = cleanName(nameController.text);
    if (voter.isEmpty) {
      showMessage('Please type your name before voting.');
      return;
    }
    if (voters.contains(voter)) {
      showMessage('$voter has already voted.');
      return;
    }
    setState(() {
      candidate.votes++;
      voters.add(voter);
    });
    await saveElection();
    nameController.clear();
    showMessage('Thank you $voter. Your vote for ${candidate.name} is counted.');
  }

  Future<void> addCandidate() async {
    final name = cleanName(candidateController.text);
    if (name.isEmpty) return;
    if (candidates.any((candidate) => candidate.name.toLowerCase() == name.toLowerCase())) {
      showMessage('That candidate is already on the list.');
      return;
    }
    setState(() => candidates.add(Candidate(name: name)));
    candidateController.clear();
    await saveElection();
  }

  Future<void> removeCandidate(Candidate candidate) async {
    setState(() => candidates.remove(candidate));
    await saveElection();
  }

  void openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsScreen(candidates: candidates)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    candidateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
          IconButton(onPressed: openResults, icon: const Icon(Icons.bar_chart), tooltip: 'Results'),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const KigaliWeatherCard(),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Votes so far: $totalVotes'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: candidateController,
                      decoration: const InputDecoration(
                        labelText: 'Add a candidate',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => addCandidate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: addCandidate, icon: const Icon(Icons.add), tooltip: 'Add candidate'),
                ]),
                const SizedBox(height: 8),
                if (candidates.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No candidates yet. Add one above.'),
                  )),
                ...candidates.map((candidate) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.how_to_vote),
                        title: Text(candidate.name),
                        subtitle: Text('${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'}'),
                        trailing: Wrap(spacing: 4, children: [
                          IconButton(
                            onPressed: () => removeCandidate(candidate),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete candidate',
                          ),
                          FilledButton(onPressed: () => vote(candidate), child: const Text('Vote')),
                        ]),
                      ),
                    )),
              ],
            ),
    );
  }
}

class KigaliWeatherCard extends StatefulWidget {
  const KigaliWeatherCard({super.key});

  @override
  State<KigaliWeatherCard> createState() => _KigaliWeatherCardState();
}

class _KigaliWeatherCardState extends State<KigaliWeatherCard> {
  late Future<Weather> weather;

  @override
  void initState() {
    super.initState();
    weather = fetchKigaliWeather();
  }

  void retry() => setState(() => weather = fetchKigaliWeather());

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Weather>(
          future: weather,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Loading Kigali weather…'),
              ]);
            }
            if (snapshot.hasError) {
              return Row(children: [
                const Expanded(child: Text('Could not load Kigali weather. Check your internet.')),
                TextButton(onPressed: retry, child: const Text('Retry')),
              ]);
            }
            final current = snapshot.data!;
            return Row(children: [
              const Icon(Icons.wb_cloudy_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Kigali weather  ·  ${current.temperature.round()}°C\n${current.description}, humidity ${current.humidity}%',
              )),
              IconButton(onPressed: retry, icon: const Icon(Icons.refresh), tooltip: 'Refresh weather'),
            ]);
          },
        ),
      ),
    );
  }
}
