import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final UserDataService _dataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _dataService.settingsStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final smsEnabled = data['smsTwoFactorEnabled'] as bool? ?? false;
          final emailEnabled = data['emailTwoFactorEnabled'] as bool? ?? true;

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
                    Icon(Icons.verified_user, size: 70, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      'Add an extra security check when signing in.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _switchTile(
                title: 'SMS Verification',
                subtitle: 'Receive a code on your phone',
                value: smsEnabled,
                onChanged: (value) =>
                    _dataService.updateSettings({'smsTwoFactorEnabled': value}),
              ),
              _switchTile(
                title: 'Email Verification',
                subtitle: 'Receive a code on your email',
                value: emailEnabled,
                onChanged: (value) => _dataService.updateSettings({
                  'emailTwoFactorEnabled': value,
                }),
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
