import 'package:flutter/material.dart';
import 'about_app_screen.dart';
import 'contact_us_screen.dart';
import 'email_support_screen.dart';
import 'faqs_screen.dart';
import 'send_feedback_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Icon(Icons.support_agent, size: 70, color: Colors.green),
                  SizedBox(height: 10),
                  Text(
                    "Need Help?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Contact us or browse frequently asked questions.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _tile(context, Icons.question_answer, "FAQs", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqsScreen()),
              );
            }),
            _tile(context, Icons.email, "Email Support", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmailSupportScreen()),
              );
            }),
            _tile(context, Icons.phone, "Contact Us", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            }),
            _tile(context, Icons.feedback, "Send Feedback", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SendFeedbackScreen()),
              );
            }),
            _tile(context, Icons.info, "About App", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
