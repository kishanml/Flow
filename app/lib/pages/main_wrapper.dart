import 'package:flutter/material.dart';
import 'homepage.dart';
import 'repeats_page.dart';
import 'progress_page.dart';
import 'tasks_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const RepeatsPage(),
    const ProgressPage(),
    const TasksPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001B3D),
      body: Material( // THIS REMOVES THE GREEN LINES
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 1. PAGE CONTENT
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),

            // 2. THE FLOATING NAVBAR
            Positioned(
              bottom: 30,
              left: 25,
              right: 25,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navBtn(Icons.repeat_rounded, 1),
                    _midBtn(),
                    _navBtn(Icons.insights_rounded, 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, int index) {
    bool isSel = _currentIndex == index;
    return IconButton(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Icon(icon, color: isSel ? Colors.white : Colors.white38, size: 28),
    );
  }

  Widget _midBtn() {
    bool isSel = _currentIndex == 3;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 3),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D3D5E),
          shape: BoxShape.circle,
          border: isSel ? Border.all(color: Colors.white24, width: 2) : null,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}