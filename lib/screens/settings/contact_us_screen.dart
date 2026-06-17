import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _contactTile(Icons.phone, 'Phone', '+91 98765 43210'),
          _contactTile(Icons.email, 'Email', 'support@yogaapp.com'),
          _contactTile(
            Icons.access_time,
            'Support Hours',
            'Mon-Sat, 9 AM - 6 PM',
          ),
          _contactTile(Icons.location_on, 'Office', 'Hyderabad, India'),
        ],
      ),
    );
  }

  Widget _contactTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
