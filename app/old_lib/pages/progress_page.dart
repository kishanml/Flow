import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _isLoading = true;
  double _globalConsistency = 0.0;
  Map<String, Map<String, int>> _taskStats = {}; // { "Gym": {"done": 5, "total": 10} }

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
  final directory = await getApplicationDocumentsDirectory();
  
  // 1. Load the Blueprint first (The "Repeats" you want to track)
  final blueprintFile = File('${directory.path}/routine_blueprint.json');
  List<String> repeatedTaskNames = [];
  
  if (await blueprintFile.exists()) {
    List<dynamic> blueprintData = jsonDecode(await blueprintFile.readAsString());
    repeatedTaskNames = blueprintData.map((e) => e['task'].toString()).toList();
  }

  final List<FileSystemEntity> files = directory.listSync();
  int totalDone = 0;
  int totalScheduled = 0;
  Map<String, Map<String, int>> tempStats = {};

  // 2. Iterate through all daily JSON files
  for (var file in files) {
    if (file is File && file.path.contains('daily_')) {
      try {
        String content = await file.readAsString();
        List<dynamic> dayTasks = jsonDecode(content);

        for (var task in dayTasks) {
          String name = task['task'];
          
          // --- FILTER: Only process if this task exists in your Repeats list ---
          if (repeatedTaskNames.contains(name)) {
            int isDone = task['done'] ?? 0;

            if (!tempStats.containsKey(name)) {
              tempStats[name] = {"done": 0, "total": 0};
            }
            
            tempStats[name]!["total"] = tempStats[name]!["total"]! + 1;
            if (isDone == 1) {
              tempStats[name]!["done"] = tempStats[name]!["done"]! + 1;
              totalDone++;
            }
            totalScheduled++;
          }
        }
      } catch (e) {
        print("Error parsing file: $e");
      }
    }
  }

  setState(() {
    _taskStats = tempStats;
    _globalConsistency = totalScheduled > 0 ? totalDone / totalScheduled : 0.0;
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E212D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Consistency Meter", 
          style: TextStyle(color: Color(0xFF1E212D), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- GLOBAL SCORE CARD ---
                  _buildGlobalScore(),
                  
                  const SizedBox(height: 40),
                  
                  const Text(
                    "Task Specifics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E212D)),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- TASK LIST ---
                  ..._taskStats.entries.map((entry) {
                    double progress = entry.value['done']! / entry.value['total']!;
                    return _buildTaskMeter(entry.key, progress, entry.value['done']!, entry.value['total']!);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalScore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E212D),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: _globalConsistency,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  color: Colors.purpleAccent,
                ),
              ),
              Text(
                "${(_globalConsistency * 100).toInt()}%",
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Overall Consistency",
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMeter(String name, double progress, int done, int total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              Text("$done/$total", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF4F6F9),
              color: Colors.purple.withOpacity(0.8),
            ),
          ),
        ],
      ),
      
    );
  }
}