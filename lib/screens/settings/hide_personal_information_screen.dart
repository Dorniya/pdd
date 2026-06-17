import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class HidePersonalInformationScreen extends StatefulWidget {
  const HidePersonalInformationScreen({super.key});

  @override
  State<HidePersonalInformationScreen> createState() =>
      _HidePersonalInformationScreenState();
}

class _HidePersonalInformationScreenState
    extends State<HidePersonalInformationScreen> {
  final UserDataService _dataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Hide Personal Information'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _dataService.settingsStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final hideEmail = data['hideEmail'] as bool? ?? true;
          final hideProfileName = data['hideProfileName'] as bool? ?? false;
          final hideWorkoutStats = data['hideWorkoutStats'] as bool? ?? false;

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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.visibility_off, size: 70, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      'Choose what information should stay private in your profile.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _switchTile(
                title: 'Hide Email Address',
                subtitle: 'Do not show email on profile',
                value: hideEmail,
                onChanged: (value) =>
                    _dataService.updateSettings({'hideEmail': value}),
              ),
              _switchTile(
                title: 'Hide Profile Name',
                subtitle: 'Show only a generic user name',
                value: hideProfileName,
                onChanged: (value) =>
                    _dataService.updateSettings({'hideProfileName': value}),
              ),
              _switchTile(
                title: 'Hide Workout Stats',
                subtitle: 'Keep sessions and streak private',
                value: hideWorkoutStats,
                onChanged: (value) =>
                    _dataService.updateSettings({'hideWorkoutStats': value}),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }
}
