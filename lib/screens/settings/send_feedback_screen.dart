import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final feedbackController = TextEditingController();
  final UserDataService _dataService = UserDataService();
  double rating = 4;
  bool loading = false;

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your feedback.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await _dataService.addFeedback(
        rating: rating.round(),
        message: feedbackController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.feedback, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              'Rating: ${rating.round()} / 5',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: Colors.green,
              label: rating.round().toString(),
              onChanged: (value) {
                setState(() => rating = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Your feedback',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  loading ? 'Submitting...' : 'Submit Feedback',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
