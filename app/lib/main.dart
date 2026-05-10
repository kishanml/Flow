import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/loading_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, 
    systemNavigationBarColor: Color(0xFFF4F6F9), 
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const YieldApp());
}

class YieldApp extends StatelessWidget {
  const YieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flow',
      
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