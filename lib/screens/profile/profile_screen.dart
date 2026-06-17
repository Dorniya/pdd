import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/progress_service.dart';
import '../../services/user_data_service.dart';
import '../settings/settings_screen.dart';
import 'favorites_screen.dart';
import 'workout_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final dataService = UserDataService();
    final progressService = ProgressService();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 15),

            StreamBuilder(
              stream: dataService.profileStream(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = data?['name'] as String?;
                final email = data?['email'] as String?;

                return Column(
                  children: [
                    Text(
                      name?.isNotEmpty == true ? name! : "User",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email?.isNotEmpty == true
                          ? email!
                          : user?.email ?? "Beginner Yoga Practitioner",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            StreamBuilder<ProgressStats>(
              stream: progressService.statsStream(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? const ProgressStats.empty();
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(color: Colors.green);
                }
                if (snapshot.hasError) {
                  return Text(
                    'Unable to load stats: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCard("Sessions", stats.totalSessions.toString()),
                    _statCard("Minutes", stats.totalMinutes.toString()),
                    _statCard("Streak", stats.streakDays.toString()),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            _optionTile(
              Icons.history,
              "Workout History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutHistoryScreen(),
                  ),
                );
              },
            ),
            _optionTile(
              Icons.favorite,
              "Favorites",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),
            _optionTile(
              Icons.settings,
              "Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _optionTile(
              Icons.logout,
              "Logout",
              onTap: () async {
                await AuthService().logout();

                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statCard(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }

  static Widget _optionTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
