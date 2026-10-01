import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'firebase_options.dart';
import 'shared/services/ride_alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RideAlertService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: UperApp()));
}

class UperApp extends StatelessWidget {
  const UperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uper',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car, size: 100, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Uper',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Peer-to-Peer Carpooling App in Nigeria',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
