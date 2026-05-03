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

  @override
  void initState() {
    super.initState();
    _timeStream = Stream<DateTime>.periodic(
      const Duration(seconds: 1), 
      (_) => DateTime.now()
    ).asBroadcastStream();
    
    _loadRealTasks();
  }

 Future<void> _loadRealTasks() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';
      final Directory flowDir = Directory(folderPath);

      // 1. Ensure the directory exists
      if (!await flowDir.exists()) {
        await flowDir.create(recursive: true);
      }

      DateTime today = DateTime.now();
      DateTime todayMidnight = DateTime(today.year, today.month, today.day);
      String todayKey = DateFormat('yyyy-MM-dd').format(today);

      File todayFile = File('$folderPath/daily_$todayKey.json');
      File bpFile = File('$folderPath/frequent_schedule.json');

      // --- 2. BOOTSTRAPPER: Create today's file if it's a new day ---
      if (!await todayFile.exists()) {
        List<Map<String, dynamic>> initialTasks = [];
        
        // If there's a frequent schedule, copy it to today
        if (await bpFile.exists()) {
          List<dynamic> bp = jsonDecode(await bpFile.readAsString());
          initialTasks = bp.map((e) => {
            "task": e['task'],
            "start": e['start'],
            "end": e['end'],
            "done": 0,
            "duration_label": "today"
          }).toList();
          
          // Sort chronologically
          initialTasks.sort((a, b) => a['start'].compareTo(b['start']));
        }
        
        // Save the newly created day to storage
        await todayFile.writeAsString(jsonEncode(initialTasks));
        debugPrint("Created new daily file for today: daily_$todayKey.json");
      }

      List<Map<String, dynamic>> pendingTasks = [];

      // 3. Scan the directory for all daily files
      List<FileSystemEntity> files = flowDir.listSync();

      for (var file in files) {
        String fileName = file.uri.pathSegments.last;

        if (fileName.startsWith('daily_') && fileName.endsWith('.json')) {
          String dateString = fileName.replaceAll('daily_', '').replaceAll('.json', '');
          
          try {
            DateTime fileDate = DateFormat('yyyy-MM-dd').parse(dateString);

            // We only check Today and Past days
            if (fileDate.isBefore(todayMidnight) || fileDate.isAtSameMomentAs(todayMidnight)) {
              String content = await File(file.path).readAsString();
              List<dynamic> decoded = jsonDecode(content);

              for (var item in decoded) {
                Map<String, dynamic> task = Map<String, dynamic>.from(item);

                if (task['done'] == 0) {
                  task['is_overdue'] = fileDate.isBefore(todayMidnight);
                  task['file_date'] = dateString; 
                  
                  pendingTasks.add(task);
                }
              }
            }
          } catch (e) {
            // Ignore files with invalid date formats
          }
        }
      }

      // 4. Sort the tasks: Overdue ones at the top, then by start time
      pendingTasks.sort((a, b) {
        if (a['is_overdue'] && !b['is_overdue']) return -1;
        if (!a['is_overdue'] && b['is_overdue']) return 1;
        return a['start'].compareTo(b['start']);
      });

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
    const Color primaryDark = Color(0xFF001B3D);
    const Color cardColor = Color(0xFF1D3D5E);

    return Scaffold(
      backgroundColor: primaryDark,
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
                  const Center(
                    child: Column(
                      children: [
                        Text("Design your days.", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        Text("Define your life.", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TIME & LOCATION CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<DateTime>(
                          stream: _timeStream,
                          builder: (context, snapshot) {
                            final time = snapshot.data ?? DateTime.now();
                            return Text(
                              DateFormat('HH : mm').format(time),
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Kishan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            StreamBuilder<DateTime>(
                              stream: _timeStream,
                              builder: (context, snapshot) {
                                final time = snapshot.data ?? DateTime.now();
                                return Text(
                                  DateFormat('dd MMM yyyy').format(time),
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text("Pending Tasks", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // LIVE TASK LIST (READ ONLY)
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _tasks.isEmpty
                            ? const Center(child: Text("All caught up!", style: TextStyle(color: Colors.white38, fontSize: 18)))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: _tasks.length,
                                itemBuilder: (context, index) => _buildTaskTile(
                                  _tasks[index], 
                                  cardColor
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),

          // 2. PERSISTENT NAVBAR
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black, 
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.repeat, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RepeatsPage()))),
                  _addIcon(() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TasksPage()))),
                  _navIcon(Icons.insights, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProgressPage()))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- READ-ONLY TASK TILE ---
  Widget _buildTaskTile(Map<String, dynamic> item, Color defaultColor) {
    bool isOverdue = item['is_overdue'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: defaultColor, 
        borderRadius: BorderRadius.circular(10),
        border: isOverdue ? Border.all(color: Colors.redAccent, width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: ListTile(
          leading: Icon(
            isOverdue ? Icons.priority_high_rounded : Icons.pending_actions, 
            color: isOverdue ? Colors.redAccent : Colors.white54, // Dimmer white to indicate read-only
            size: 28
          ),
          title: Text(
            item['task'], 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          subtitle: Text(
            isOverdue 
              ? "Overdue from ${item['file_date']} • ${item['start']}"
              : "Today • ${item['start']}", 
            style: TextStyle(
              color: isOverdue ? Colors.redAccent.withOpacity(0.8) : Colors.white70, 
              fontSize: 13
            )
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
          backgroundColor: const Color(0xFF1D3D5E),
          child: Icon(icon, color: Colors.white),
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
        child: const CircleAvatar(
          radius: 35,
          backgroundColor: Color(0xFF1D3D5E),
          child: Icon(Icons.add, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}