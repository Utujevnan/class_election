import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/candidate.dart';
import '../state/election_state.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final election = context.read<ElectionState>();
    final voter = cleanName(_voterController.text).isEmpty
        ? (user.email ?? 'Your account')
        : cleanName(_voterController.text);

    setState(() => _working = true);
    try {
      await election.vote(candidate, voter);
      _voterController.clear();
      _message('Thank you $voter. Your vote for ${candidate.name} is counted.');
    } on StateError catch (error) {
      _message(
        error.message == 'already-voted'
            ? '$voter has already voted.'
            : 'That candidate is no longer available.',
      );
    } catch (_) {
      _message('Could not submit your vote. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _addCandidate() async {
    final name = cleanName(_candidateController.text);
    if (name.isEmpty) return;
    final election = context.read<ElectionState>();
    setState(() => _working = true);
    try {
      await election.addCandidate(name);
      _candidateController.clear();
    } catch (_) {
      _message('Could not add the candidate. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _removeCandidate(Candidate candidate) async {
    final election = context.read<ElectionState>();
    try {
      await election.removeCandidate(candidate);
    } catch (_) {
      _message('Could not remove the candidate. Please try again.');
    }
  }

  Future<void> _editCandidate(Candidate candidate) async {
    final election = context.read<ElectionState>();
    final controller = TextEditingController(text: candidate.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit candidate'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Candidate name'),
          onSubmitted: (value) => Navigator.pop(context, cleanName(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, cleanName(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == candidate.name) return;
    try {
      await election.editCandidate(candidate.id, name);
    } catch (_) {
      _message('Could not edit the candidate. Please try again.');
    }
  }

  void _openResults() {
    final election = context.read<ElectionState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ElectionState>.value(
          value: election,
          child: const ResultsScreen(),
        ),
      ),
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
    final election = context.watch<ElectionState>();
    final candidates = election.visibleCandidates;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
          IconButton(
            onPressed: _openResults,
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
      body: election.error != null
          ? _candidateLoadError(election.error!)
          : election.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const KigaliWeatherCard(),
                const SizedBox(height: 12),
                TextField(
                  controller: _voterController,
                  decoration: const InputDecoration(
                    labelText: 'Your name (optional)',
                    helperText: 'One vote per signed-in account',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
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
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total votes: ${election.totalVotes}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            ('all', 'All'),
                            ('with_votes', 'With votes'),
                            ('without_votes', 'No votes'),
                          ]
                          .map(
                            (option) => ChoiceChip(
                              label: Text(option.$2),
                              selected: election.filter == option.$1,
                              onSelected: (_) => context
                                  .read<ElectionState>()
                                  .setFilter(option.$1),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                if (election.candidates.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No candidates yet. Add one above.'),
                    ),
                  )
                else if (candidates.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No candidates match this filter.'),
                    ),
                  ),
                ...candidates.map(
                  (candidate) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.how_to_vote),
                      title: Text(candidate.name),
                      subtitle: Text(
                        '${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: () => _editCandidate(candidate),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit candidate',
                          ),
                          IconButton(
                            onPressed: () => _removeCandidate(candidate),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete candidate',
                          ),
                          FilledButton(
                            onPressed: _working || election.hasVoted
                                ? null
                                : () => _vote(candidate),
                            child: Text(election.hasVoted ? 'Voted' : 'Vote'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _candidateLoadError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            const Text('Could not load candidates'),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: context.read<ElectionState>().retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
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
              return const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading Kigali weather…'),
                ],
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Could not load Kigali weather. Check your internet.',
                    ),
                  ),
                  TextButton(onPressed: _retry, child: const Text('Retry')),
                ],
              );
            }
            final current = snapshot.data!;
            return Row(
              children: [
                const Icon(Icons.wb_cloudy_outlined, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kigali weather · ${current.temperature.round()}°C\n'
                    '${current.description}, humidity ${current.humidity}%',
                  ),
                ),
                IconButton(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh weather',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
