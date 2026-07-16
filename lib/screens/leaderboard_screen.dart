import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: StreamBuilder<List<UserProfile>>(
        stream: firestoreService.watchLeaderboard(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No rankings yet.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(user.displayName.isEmpty
                    ? 'Anonymous'
                    : user.displayName),
                subtitle: Text('${user.level} · ${user.currentStreak}-day streak'),
                trailing: Text(
                  '${user.points} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
