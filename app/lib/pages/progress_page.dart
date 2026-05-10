import 'package:app/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'repeats_page.dart';
import 'tasks_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _isLoading = true;
  double _globalConsistency = 0.0;
  Map<String, Map<String, dynamic>> _taskStats = {};
  
  DateTime _selectedMonth = DateTime.now();

  // --- NEW THEME COLORS ---
  final Color bgColor = const Color(0xFF161719);
  final Color cardBgColor = const Color(0xFF1C1D21);
  final Color surfaceColor = const Color(0xFF222A26);
  final Color elementGray = const Color(0xFF31353A);
  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFF9BA3AA);
  final Color accentMint = const Color(0xFFC2E5CD);

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';
      final Directory flowDir = Directory(folderPath);

      if (!await flowDir.exists()) {
        setState(() {
          _taskStats = {};
          _globalConsistency = 0.0;
          _isLoading = false;
        });
        return;
      }

      final bpFile = File('$folderPath/frequent_schedule.json');
      Map<String, String> repeatedTasksTime = {};

      if (await bpFile.exists()) {
        List<dynamic> bp = jsonDecode(await bpFile.readAsString());
        for (var e in bp) {
          repeatedTasksTime[e['task']] = "${e['start']} - ${e['end']}";
        }
      }

      final List<FileSystemEntity> files = flowDir.listSync();
      int totalDone = 0;
      int totalScheduled = 0;
      Map<String, Map<String, dynamic>> tempStats = {};

      for (var file in files) {
        String fileName = file.uri.pathSegments.last;
        
        if (file is File && fileName.startsWith('daily_') && fileName.endsWith('.json')) {
          String dateString = fileName.replaceAll('daily_', '').replaceAll('.json', '');
          
          try {
            DateTime fileDate = DateFormat('yyyy-MM-dd').parse(dateString);
            
            if (fileDate.year == _selectedMonth.year && fileDate.month == _selectedMonth.month) {
              List<dynamic> dayTasks = jsonDecode(await file.readAsString());
              
              for (var task in dayTasks) {
                String name = task['task'];
                if (repeatedTasksTime.containsKey(name)) {
                  if (!tempStats.containsKey(name)) {
                    tempStats[name] = {
                      "done": 0,
                      "total": 0,
                      "time": repeatedTasksTime[name],
                    };
                  }
                  tempStats[name]!["total"]++;
                  
                  if (task['done'] == 1) {
                    tempStats[name]!["done"]++;
                    totalDone++;
                  }
                  totalScheduled++;
                }
              }
            }
          } catch (e) {
            debugPrint("Skipping invalid date file: $fileName");
          }
        }
      }

      setState(() {
        _taskStats = tempStats;
        _globalConsistency = totalScheduled > 0
            ? (totalDone / totalScheduled) * 100
            : 0.0;
      });
    } catch (e) {
      debugPrint("Error calculating stats: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _isLoading = true;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
    _calculateStats();
  }

  // --- SMOOTH PAGE TRANSITION HELPER ---
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
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
                children: [
                  const SizedBox(height: 20),

                  // TOP BACK OPTION
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textPrimary,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            _fadeRoute(const HomePage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      Expanded(
                        child: Text(
                          "Progress",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),

                  const SizedBox(height: 20),

                  // MONTH SELECTOR UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded, color: textSecondary, size: 30),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded, 
                          color: _selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year 
                              ? Colors.transparent 
                              : textSecondary, 
                          size: 30
                        ),
                        onPressed: () {
                          if (!(_selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year)) {
                            _changeMonth(1);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // CONSISTENCY HIGHLIGHT CARD (Using the Slate Green surface color)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Monthly Consistency",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${_globalConsistency.toInt()}",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              " %",
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Routine Breakdown",
                      style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // TASK SPECIFIC STATS
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: accentMint))
                        : _taskStats.isEmpty
                            ? Center(
                                child: Text(
                                  "No data for ${DateFormat('MMMM').format(_selectedMonth)}.", 
                                  style: TextStyle(color: textSecondary, fontSize: 16)
                                )
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: _taskStats.length,
                                itemBuilder: (context, index) {
                                  String taskName = _taskStats.keys.elementAt(index);
                                  var data = _taskStats[taskName]!;
                                  return _buildProgressTile(
                                    taskName,
                                    data['time'],
                                    data['done'],
                                    data['total'],
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FIXED NAVBAR (Smooth Fade Routing)
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF000000), // Pure black for floating contrast
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.repeat, () => Navigator.pushReplacement(context, _fadeRoute(const RepeatsPage()))),
                  _addIcon(() => Navigator.pushReplacement(context, _fadeRoute(const TasksPage()))),
                  _navIcon(Icons.insights, () {}, isSelected: true), // Active tab
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REFINED PROGRESS TILE ---
  Widget _buildProgressTile(String title, String time, int done, int total) {
    double completionRate = total > 0 ? done / total : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: elementGray,
                child: Icon(Icons.show_chart_rounded, color: accentMint, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                "$done / $total",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: elementGray,
              valueColor: AlwaysStoppedAnimation<Color>(accentMint),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // --- POLISHED NAVBAR ICONS ---
  Widget _navIcon(IconData icon, VoidCallback onTap, {bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: elementGray,
          // Active icon gets the Mint color to stand out, inactive gets textSecondary
          child: Icon(icon, color: isSelected ? accentMint : textSecondary),
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
          backgroundColor: accentMint,
          child: Icon(Icons.add, color: bgColor, size: 40),
        ),
      ),
    );
  }
}