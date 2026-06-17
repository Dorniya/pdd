import 'package:flutter/material.dart';
import 'yoga_timer_screen.dart';
import 'yoga_pose_data.dart';

class YogaDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const YogaDetailScreen({
    super.key,
    required this.title,
    this.subtitle = '',
    this.description =
        'Practice this yoga pose to improve flexibility, balance and wellness.',
  });

  @override
  Widget build(BuildContext context) {
    final pose = poseInfoFor(title);
    final detailSubtitle = subtitle.isNotEmpty ? subtitle : pose.subtitle;
    final detailDescription =
        description !=
            'Practice this yoga pose to improve flexibility, balance and wellness.'
        ? description
        : pose.description;

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.green.shade50,
                alignment: Alignment.center,
                child: Image.asset(
                  pose.imagePath,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.self_improvement,
                      size: 84,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (detailSubtitle.isNotEmpty) ...[
              Text(
                detailSubtitle,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    pose.duration,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(detailDescription, textAlign: TextAlign.center),

            const SizedBox(height: 24),

            _InfoSection(title: 'Benefits', items: pose.benefits),

            const SizedBox(height: 18),

            _InfoSection(title: 'How to Practice', items: pose.steps),

            const SizedBox(height: 18),

            _InfoSection(title: 'Tips', items: pose.tips),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YogaTimerScreen(title: title),
                    ),
                  );
                },
                child: const Text("Start Session"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(item),
          ),
      ],
    );
  }
}
