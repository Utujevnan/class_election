import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/election_state.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final election = context.watch<ElectionState>();
    final candidates = election.candidates;
    final ranked = election.rankedCandidates;
    final total = election.totalVotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: election.error != null
          ? Center(child: Text(election.error!, textAlign: TextAlign.center))
          : election.loading
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
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
                        election.winnerBanner,
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
                                    '${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'} · ${election.votePercent(candidate)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: election.voteShare(candidate),
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
