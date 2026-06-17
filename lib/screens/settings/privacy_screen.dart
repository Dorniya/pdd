import 'package:flutter/material.dart';
import 'biometric_login_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_data_screen.dart';
import 'hide_personal_information_screen.dart';
import 'two_factor_auth_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Privacy & Security"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.security, size: 70, color: Colors.green),
                  SizedBox(height: 10),
                  Text(
                    "Your privacy matters",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Manage your account security and privacy settings.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _tile(context, Icons.lock, "Change Password", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            }),

            _tile(context, Icons.fingerprint, "Biometric Login", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BiometricLoginScreen()),
              );
            }),

            _tile(
              context,
              Icons.verified_user,
              "Two-Factor Authentication",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TwoFactorAuthScreen(),
                  ),
                );
              },
            ),

            _tile(
              context,
              Icons.visibility_off,
              "Hide Personal Information",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HidePersonalInformationScreen(),
                  ),
                );
              },
            ),

            _tile(context, Icons.delete_forever, "Delete Account Data", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeleteAccountDataScreen(),
                ),
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
