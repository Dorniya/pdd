import 'package:flutter/material.dart';
import 'yoga_detail_screen.dart';
import 'yoga_pose_data.dart';

class YogaListScreen extends StatelessWidget {
  const YogaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yoga Sessions"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: yogaPoses.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.green),
              title: Text(yogaPoses[index].title),
              subtitle: Text(
                '${yogaPoses[index].subtitle} - ${yogaPoses[index].duration}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        YogaDetailScreen(title: yogaPoses[index].title),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
