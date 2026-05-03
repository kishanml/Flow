import 'package:app/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _runBootloader();
  }

  Future<void> _runBootloader() async {
    // 1. Get the local phone/computer directory
    final directory = await getApplicationDocumentsDirectory();
    final blueprintFile = File('${directory.path}/routine_blueprint.json');
    
    // 🔍 ADDED: Print the exact file path to your debug console
    print('\n=========================================');
    print('📂 CHECKING/STORING BLUEPRINT AT:');
    print(blueprintFile.path);
    print('=========================================\n');

    // Simulating the loading time for the splash screen aesthetic
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          // 👇 Route straight to the HomePage
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            const Center(
              child: Text(
                'FLOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              // Placeholder text in case the logo isn't in pubspec.yaml yet
              child: const Text(
                'yield100',
                style: TextStyle(
                  color: Colors.redAccent, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}