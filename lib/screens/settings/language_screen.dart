import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final UserDataService _dataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Language"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _dataService.settingsStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final selectedLanguage = data['language'] as String? ?? 'English';

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load language: ${snapshot.error}'),
            );
          }

          return RadioGroup<String>(
            groupValue: selectedLanguage,
            onChanged: (value) {
              if (value == null) return;
              _dataService.updateSettings({'language': value});
            },
            child: const Column(
              children: [
                RadioListTile(title: Text("English"), value: "English"),
                RadioListTile(title: Text("Hindi"), value: "Hindi"),
                RadioListTile(title: Text("Telugu"), value: "Telugu"),
                RadioListTile(title: Text("Tamil"), value: "Tamil"),
              ],
            ),
          );
        },
      ),
    );
  }
}
