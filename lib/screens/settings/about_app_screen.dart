import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.self_improvement, size: 90, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'Yoga App',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Version 1.0.0'),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Yoga App helps you practice poses, track workout history, save favorites, and build a healthier daily routine.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _infoTile(Icons.favorite, 'Made for mindful daily practice'),
            _infoTile(Icons.security, 'Privacy and account settings included'),
            _infoTile(Icons.timeline, 'Progress and history tracking'),
          ],
        ),
      ),
    );
  }

  static Widget _infoTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
      ),
    );
  }
}
