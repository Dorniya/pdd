import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  final UserDataService _dataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Biometric Login'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _dataService.settingsStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final fingerprintEnabled =
              data['fingerprintEnabled'] as bool? ?? false;
          final faceUnlockEnabled = data['faceUnlockEnabled'] as bool? ?? false;

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
              _header(
                Icons.fingerprint,
                'Use your device biometrics to unlock the app faster.',
              ),
              const SizedBox(height: 16),
              _switchTile(
                title: 'Fingerprint Login',
                subtitle: 'Unlock the app with your fingerprint',
                value: fingerprintEnabled,
                onChanged: (value) =>
                    _dataService.updateSettings({'fingerprintEnabled': value}),
              ),
              _switchTile(
                title: 'Face Unlock',
                subtitle: 'Use face recognition when available',
                value: faceUnlockEnabled,
                onChanged: (value) =>
                    _dataService.updateSettings({'faceUnlockEnabled': value}),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 70, color: Colors.green),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
        ],
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
