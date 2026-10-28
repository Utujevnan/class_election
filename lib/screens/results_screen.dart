import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../utils/results.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.candidates});

  final List<Candidate> candidates;

  @override
  Widget build(BuildContext context) {
    final ranked = rankCandidates(candidates);
    final total = totalVotes(candidates);

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: candidates.isEmpty
          ? const Center(child: Text('No candidates to show.'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  bannerText(candidates),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Total votes: $total'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: ranked.length,
                itemBuilder: (context, index) {
                  final candidate = ranked[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${index + 1}. ${candidate.name}'),
                            Text(
                              '${candidate.votes} ${voteWord(candidate.votes)} · ${percentText(candidate.votes, total)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: share(candidate.votes, total),
                          minHeight: 10,
                        ),
                      ],
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