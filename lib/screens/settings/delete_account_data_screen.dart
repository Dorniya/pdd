import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class DeleteAccountDataScreen extends StatefulWidget {
  const DeleteAccountDataScreen({super.key});

  @override
  State<DeleteAccountDataScreen> createState() =>
      _DeleteAccountDataScreenState();
}

class _DeleteAccountDataScreenState extends State<DeleteAccountDataScreen> {
  bool deleteWorkoutHistory = true;
  bool deleteFavorites = true;
  bool deleteProfile = false;
  final UserDataService _dataService = UserDataService();

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account Data?'),
          content: const Text(
            'This will remove the selected account data from this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _dataService.deleteSelectedData(
                    workoutHistory: deleteWorkoutHistory,
                    favorites: deleteFavorites,
                    profile: deleteProfile,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Selected data deleted.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Delete Account Data'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
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
                Icon(Icons.delete_forever, size: 70, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  'Select which data you want to delete.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _checkTile(
            title: 'Workout History',
            value: deleteWorkoutHistory,
            onChanged: (value) {
              setState(() => deleteWorkoutHistory = value ?? false);
            },
          ),
          _checkTile(
            title: 'Favorites',
            value: deleteFavorites,
            onChanged: (value) {
              setState(() => deleteFavorites = value ?? false);
            },
          ),
          _checkTile(
            title: 'Profile Information',
            value: deleteProfile,
            onChanged: (value) {
              setState(() => deleteProfile = value ?? false);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _confirmDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete Selected Data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(title),
        value: value,
        activeColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }
}
