import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../utils/names.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final List<Candidate> candidates = [
    Candidate(name: 'Keza'),
    Candidate(name: 'Mutoni'),
    Candidate(name: 'Jean'),
  ];
  final List<String> voters = [];
  final TextEditingController nameController = TextEditingController();

  int get totalVotes => voters.length;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void vote(Candidate candidate) {
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
    nameController.clear();
    showMessage('Thank you $voter. Your vote for ${candidate.name} is counted.');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Election')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Votes so far: $totalVotes'),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                child: Text('No candidates yet.'),
              )
                  : ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.how_to_vote),
                      title: Text(candidate.name),
                      trailing: FilledButton(
                        onPressed: () => vote(candidate),
                        child: const Text('Vote'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}