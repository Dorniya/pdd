import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final UserDataService _dataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder(
        stream: _dataService.settingsStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final workoutReminder = data['workoutReminder'] as bool? ?? true;
          final progressUpdates = data['progressUpdates'] as bool? ?? true;
          final motivationalTips = data['motivationalTips'] as bool? ?? false;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load settings: ${snapshot.error}'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text("Workout Reminders"),
                subtitle: const Text("Receive daily yoga reminders"),
                value: workoutReminder,
                activeThumbColor: Colors.green,
                onChanged: (value) =>
                    _dataService.updateSettings({'workoutReminder': value}),
              ),
              SwitchListTile(
                title: const Text("Progress Updates"),
                subtitle: const Text("Track your yoga achievements"),
                value: progressUpdates,
                activeThumbColor: Colors.green,
                onChanged: (value) =>
                    _dataService.updateSettings({'progressUpdates': value}),
              ),
              SwitchListTile(
                title: const Text("Motivational Tips"),
                subtitle: const Text("Get wellness tips and inspiration"),
                value: motivationalTips,
                activeThumbColor: Colors.green,
                onChanged: (value) =>
                    _dataService.updateSettings({'motivationalTips': value}),
              ),
            ],
          );
        },
      ),
    );
  }
}
