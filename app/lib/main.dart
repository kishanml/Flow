import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/loading_page.dart';

void main() {
  // Ensure the status bar is transparent and icons are dark for the light theme
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light bg
    systemNavigationBarColor: Color(0xFFF4F6F9), // Matches app background
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const Yield100App());
}

class Yield100App extends StatelessWidget {
  const Yield100App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yield100 Flow',
      
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'Inter', 
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E212D),
          primary: const Color(0xFF1E212D),
          secondary: Colors.redAccent,
          surface: Colors.white,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      
      // Starting with the new Splash Screen
      home: const SplashScreen(),
    );
  }
}