import 'package:flutter/material.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Leaderboard Screen - TODO')),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }
}
