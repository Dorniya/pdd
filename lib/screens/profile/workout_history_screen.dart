import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = UserDataService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: dataService.workoutHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final items =
              snapshot.data?.docs
                  .map((doc) => _WorkoutHistoryItem.fromMap(doc.data()))
                  .toList() ??
              [];

          if (items.isEmpty) {
            return const Center(child: Text('No workout history yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(
                      Icons.self_improvement,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${item.date} - ${item.duration}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _WorkoutHistoryDetailScreen(item: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkoutHistoryItem {
  final String title;
  final String date;
  final String duration;
  final String calories;
  final String description;
  final List<String> poses;
  final int? poseAccuracy;
  final String completionStatus;
  final List<String> incorrectParts;

  const _WorkoutHistoryItem({
    required this.title,
    required this.date,
    required this.duration,
    required this.calories,
    required this.description,
    required this.poses,
    required this.poseAccuracy,
    required this.completionStatus,
    required this.incorrectParts,
  });

  factory _WorkoutHistoryItem.fromMap(Map<String, dynamic> data) {
    return _WorkoutHistoryItem(
      title: data['title'] as String? ?? '',
      date: data['date'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      calories: data['calories'] as String? ?? '',
      description: data['description'] as String? ?? '',
      poses: List<String>.from(data['poses'] as List? ?? const []),
      poseAccuracy: data['poseAccuracy'] as int?,
      completionStatus: data['completionStatus'] as String? ?? '',
      incorrectParts: List<String>.from(
        data['incorrectParts'] as List? ?? const [],
      ),
    );
  }
}

class _WorkoutHistoryDetailScreen extends StatelessWidget {
  final _WorkoutHistoryItem item;

  const _WorkoutHistoryDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(item.title), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.green.shade50,
                child: const Icon(
                  Icons.self_improvement,
                  size: 64,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _SummaryCard(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: item.date,
                ),
                _SummaryCard(
                  icon: Icons.timer,
                  title: 'Time',
                  value: item.duration,
                ),
                _SummaryCard(
                  icon: Icons.local_fire_department,
                  title: 'Burn',
                  value: item.calories,
                ),
              ],
            ),
            if (item.poseAccuracy != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Pose Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: item.poseAccuracy! / 100,
                      color: Colors.green,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text('${item.poseAccuracy}% accuracy'),
                    Text(
                      item.completionStatus == 'completed'
                          ? 'Completed'
                          : 'Needs more practice',
                    ),
                    if (item.incorrectParts.isNotEmpty)
                      Text('Focus areas: ${item.incorrectParts.join(', ')}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Completed Poses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final pose in item.poses)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(pose),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
