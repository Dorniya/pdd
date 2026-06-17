import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';
import '../yoga/yoga_detail_screen.dart';
import '../yoga/yoga_pose_data.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = UserDataService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: dataService.favoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final favoriteTitles =
              snapshot.data?.docs
                  .map((doc) => doc.data()['title'] as String? ?? '')
                  .where((title) => title.isNotEmpty)
                  .toList() ??
              [];

          if (favoriteTitles.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteTitles.length,
            itemBuilder: (context, index) {
              final favorite = poseInfoFor(favoriteTitles[index]);

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
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text(
                    favorite.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(favorite.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YogaDetailScreen(title: favorite.title),
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
