import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'repeats_page.dart';
import 'tasks_page.dart';
import 'progress_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<DateTime> _timeStream;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  // --- NEW THEME COLORS ---
  final Color bgColor = const Color(0xFF161719);
  final Color cardBgColor = const Color(0xFF1C1D21);
  final Color surfaceColor = const Color(0xFF222A26);
  final Color elementGray = const Color(0xFF31353A);
  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFF9BA3AA);
  final Color accentPeach = const Color(0xFFFFB4A9);
  final Color accentMint = const Color(0xFFC2E5CD);

  @override
  void initState() {
    super.initState();
    _timeStream = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).asBroadcastStream();

    _loadRealTasks();
  }

  Future<void> _loadRealTasks() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';
      final Directory flowDir = Directory(folderPath);

      if (!await flowDir.exists()) {
        await flowDir.create(recursive: true);
      }

      DateTime today = DateTime.now();
      String todayKey = DateFormat('yyyy-MM-dd').format(today);

      File todayFile = File('$folderPath/daily_$todayKey.json');
      File bpFile = File('$folderPath/frequent_schedule.json');

      // 1. BOOTSTRAPPER: Create today's file if it's a new day
      if (!await todayFile.exists()) {
        List<Map<String, dynamic>> initialTasks = [];

        if (await bpFile.exists()) {
          List<dynamic> bp = jsonDecode(await bpFile.readAsString());
          initialTasks = bp
              .map(
                (e) => {
                  "task": e['task'],
                  "start": e['start'],
                  "end": e['end'],
                  "done": 0,
                  "duration_label": "today",
                },
              )
              .toList();

          initialTasks.sort((a, b) => a['start'].compareTo(b['start']));
        }

        await todayFile.writeAsString(jsonEncode(initialTasks));
      }

      List<Map<String, dynamic>> pendingTasks = [];

      // 2. ONLY LOAD TODAY'S TASKS (Ignore all past files)
      if (await todayFile.exists()) {
        String content = await todayFile.readAsString();
        List<dynamic> decoded = jsonDecode(content);

        for (var item in decoded) {
          Map<String, dynamic> task = Map<String, dynamic>.from(item);

          // Only show it if it's not done
          if (task['done'] == 0) {
            task['is_overdue'] =
                false; // Nothing is overdue if we only look at today
            task['file_date'] = todayKey;

            pendingTasks.add(task);
          }
        }
      }

      // 3. Sort chronologically by start time
      pendingTasks.sort((a, b) => a['start'].compareTo(b['start']));

      setState(() {
        _tasks = pendingTasks;
      });
    } catch (e) {
      debugPrint("Error loading pending tasks: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // MOTIVATIONAL HEADER
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Design your days.",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "Define your life.",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TIME & LOCATION CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<DateTime>(
                          stream: _timeStream,
                          builder: (context, snapshot) {
                            final time = snapshot.data ?? DateTime.now();
                            return Text(
                              DateFormat('HH : mm').format(time),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Kishan",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<DateTime>(
                              stream: _timeStream,
                              builder: (context, snapshot) {
                                final time = snapshot.data ?? DateTime.now();
                                return Text(
                                  DateFormat('dd MMM yyyy').format(time),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Pending Tasks",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIVE TASK LIST (READ ONLY)
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(color: accentMint),
                          )
                        : _tasks.isEmpty
                        ? Center(
                            child: Text(
                              "All caught up!",
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) =>
                                _buildTaskTile(_tasks[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FIXED NAVBAR
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF000000), 
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Repeats Page
                  _navIcon(Icons.repeat, () => Navigator.pushReplacement(context, _fadeRoute(const RepeatsPage()))),
                  
                  // Tasks / Add Page
                  _addIcon(() => Navigator.pushReplacement(context, _fadeRoute(const TasksPage()))),
                  
                  // Progress Page (BROUGHT BACK!)
                  _navIcon(Icons.insights, () => Navigator.pushReplacement(context, _fadeRoute(const ProgressPage()))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED READ-ONLY TASK TILE ---
  Widget _buildTaskTile(Map<String, dynamic> item) {
    bool isOverdue = item['is_overdue'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        // Soft peach border for overdue tasks
        border: isOverdue ? Border.all(color: accentPeach, width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: ListTile(
          leading: Icon(
            isOverdue ? Icons.priority_high_rounded : Icons.circle_outlined,
            color: isOverdue ? accentPeach : textSecondary,
            size: 28,
          ),
          title: Text(
            item['task'],
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              isOverdue
                  ? "Overdue from ${item['file_date']} • ${item['start']}"
                  : "Today • ${item['start']}",
              style: TextStyle(
                color: isOverdue ? accentPeach.withOpacity(0.9) : textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- POLISHED NAV ICONS ---
  Widget _navIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: CircleAvatar(
          radius: 25,
          backgroundColor:
              elementGray, // Muted gray background for secondary buttons
          child: Icon(icon, color: textSecondary),
        ),
      ),
    );
  }

  Widget _addIcon(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(35),
        child: CircleAvatar(
          radius: 35,
          backgroundColor: accentMint, // Mint green for the primary action
          child: Icon(
            Icons.add,
            color: bgColor,
            size: 40,
          ), // Dark icon for contrast
        ),
      ),
    );
  }

  // --- SMOOTH PAGE TRANSITION HELPER ---
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
