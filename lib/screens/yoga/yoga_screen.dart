import 'package:flutter/material.dart';
import 'yoga_detail_screen.dart';

class YogaScreen extends StatelessWidget {
  const YogaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Yoga Sessions"),
        backgroundColor: Colors.green,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Choose Your Session 🧘",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _sessionCard(
            context,
            "Morning Energy Yoga",
            "15 min beginner flow",
            "Boost your energy and start fresh",
          ),

          _sessionCard(
            context,
            "Stress Relief Yoga",
            "20 min calming session",
            "Relax your mind and reduce stress",
          ),

          _sessionCard(
            context,
            "Deep Stretch Yoga",
            "25 min flexibility flow",
            "Improve flexibility and posture",
          ),

          _sessionCard(
            context,
            "Power Yoga",
            "30 min advanced flow",
            "Build strength and stamina",
          ),
        ],
      ),
    );
  }

  // 🧘 SESSION CARD (CLICK → DETAIL)
  Widget _sessionCard(
    BuildContext context,
    String title,
    String subtitle,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.self_improvement,
            color: Colors.green, size: 35),

        title: Text(title),
        subtitle: Text(subtitle),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YogaDetailScreen(
                title: title,
                subtitle: subtitle,
                description: description,
              ),
            ),
          );
        },
      ),
    );
  }
}