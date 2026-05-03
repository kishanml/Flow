import 'package:flutter/material.dart';
import 'pages/loading_page.dart'; // Make sure this matches your file name

void main() {
  // Required if you are doing file-system checks before runApp()
  WidgetsFlutterBinding.ensureInitialized(); 
  
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLOW',
      debugShowCheckedModeBanner: false,
      // Setting up a global Dark Theme to match your aesthetic
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        fontFamily: 'Roboto', // Change this if you use a custom system font
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey, // Accent color for buttons/sliders
        ),
      ),
      // Set the initial route to the Splash Screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        // '/dashboard': (context) => const DashboardScreen(),
        // Later, you can add: '/timetable': (context) => const TimetableScreen(),
      },
    );
  }
}