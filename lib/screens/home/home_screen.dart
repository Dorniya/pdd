import 'package:flutter/material.dart';

import '../../services/progress_service.dart';
import '../yoga/yoga_list_screen.dart';
import '../yoga/yoga_timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();

  @override
  void initState() {
    super.initState();
    _progressService.ensureStatsFromHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yoga Dashboard"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<ProgressStats>(
        stream: _progressService.statsStream(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? const ProgressStats.empty();

          if (snapshot.hasError) {
            debugPrint('[HomeScreen] Dashboard stream error: ${snapshot.error}');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Let's continue your yoga journey",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(color: Colors.green),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      title: "Sessions",
                      value: stats.totalSessions.toString(),
                    ),
                    _StatCard(
                      title: "Minutes",
                      value: stats.totalMinutes.toString(),
                    ),
                    _StatCard(
                      title: "Streak",
                      value: stats.streakDays.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      title: "AI Accuracy",
                      value: "${stats.averageAiAccuracy}%",
                    ),
                    _StatCard(
                      title: "AI Sessions",
                      value: stats.aiSessions.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProgressCard(stats: stats),
                const SizedBox(height: 20),
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.self_improvement,
                      label: "Start Yoga",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const YogaListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.timer,
                      label: "Timer",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const YogaTimerScreen(
                              title: "Quick Yoga Timer",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressStats stats;

  const _ProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text("Completed Sessions: ${stats.totalSessions}"),
          Text("Total Minutes: ${stats.totalMinutes}"),
          Text("Streak Days: ${stats.streakDays}"),
          Text("AI Sessions: ${stats.aiSessions}"),
          Text("Average AI Accuracy: ${stats.averageAiAccuracy}%"),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(height: 5),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
