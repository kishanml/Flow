import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'homepage.dart'; // Adjust this import to match your project structure

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Added a progress variable to track the file generation
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _prepareYourDay();
  }

  Future<void> _prepareYourDay() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';
      final Directory flowDir = Directory(folderPath);

      if (!await flowDir.exists()) {
        await flowDir.create(recursive: true);
      }

      File bpFile = File('$folderPath/frequent_schedule.json');
      List<Map<String, dynamic>> blueprintTasks = [];

      if (await bpFile.exists()) {
        List<dynamic> bp = jsonDecode(await bpFile.readAsString());
        blueprintTasks = bp.map((e) => {
          "task": e['task'],
          "start": e['start'],
          "end": e['end'],
          "done": 0,
          "duration_label": "today"
        }).toList();
        
        blueprintTasks.sort((a, b) => a['start'].compareTo(b['start']));
      }

      DateTime today = DateTime.now();
      String blueprintJson = jsonEncode(blueprintTasks); 

      for (int i = 0; i < 365; i++) {
        DateTime targetDate = today.add(Duration(days: i));
        String dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
        File dayFile = File('$folderPath/daily_$dateKey.json');

        if (!await dayFile.exists()) {
          await dayFile.writeAsString(blueprintJson);
        }

        // Update the progress bar smoothly
        if (i % 5 == 0 || i == 364) {
          setState(() {
            _progress = (i + 1) / 365.0;
          });
          // This tiny delay allows the UI to paint the progress bar moving
          // while ensuring the splash screen is visible for at least ~1 second
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }

      await Future.delayed(const Duration(milliseconds: 400));

    } catch (e) {
      debugPrint("Error preparing days: $e");
    } finally {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors extracted from your UI reference
    const Color bgColor = Color(0xFF161719);
    const Color barFillColor = Color(0xFFA0C8C6); // Light teal/cyan
    const Color barTrackColor = Color(0xFF333333); 
    const Color subTextColor = Color(0xFFA0C8C6);


    return Scaffold(
      backgroundColor: bgColor,
      // WRAPPED IN A STACK SO 'POSITIONED' WORKS
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. THE ROUND LOGO
                Container(
                  width: 120, // Adjust size as needed
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Optional: Adds a subtle premium glow behind the logo
                  ),
                  // ClipOval forces the square image into a perfect circle
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon.png', // Make sure this matches your pubspec.yaml
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 40), // Space between logo and loader

                // Sleek Linear Progress Bar
                SizedBox(
                  width: 180,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null, // Animates infinitely if 0
                      backgroundColor: barTrackColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(barFillColor),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  "Preparing your day...",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM FOOTER TEXT
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "kishanml",
                style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }}