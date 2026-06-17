import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I start a yoga session?',
      answer:
          'Open the Yoga tab, choose a pose or session, then tap Start Session.',
    ),
    _FaqItem(
      question: 'Can I track my workout history?',
      answer:
          'Yes. Go to Profile and open Workout History to view completed sessions.',
    ),
    _FaqItem(
      question: 'How do I change my password?',
      answer:
          'Open Settings, then Privacy & Security, and choose Change Password.',
    ),
    _FaqItem(
      question: 'Why am I unable to login?',
      answer:
          'Check your email and password. If the issue continues, confirm that Email/Password sign-in is enabled in Firebase.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('FAQs'), backgroundColor: Colors.green),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.question_answer, color: Colors.green),
              title: Text(
                faq.question,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(faq.answer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
