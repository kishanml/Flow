import 'package:app/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'tasks_page.dart';
import 'progress_page.dart';
import 'package:path_provider/path_provider.dart';

class RepeatsPage extends StatefulWidget {
  const RepeatsPage({Key? key}) : super(key: key);

  @override
  State<RepeatsPage> createState() => _RepeatsPageState();
}

class _RepeatsPageState extends State<RepeatsPage> {
  List<Map<String, dynamic>> _routineTasks = [];
  bool _isLoading = true;

  // --- NEW THEME COLORS ---
  final Color bgColor = const Color(0xFF161719);
  final Color cardBgColor = const Color(0xFF1C1D21);
  final Color surfaceColor = const Color(0xFF222A26);
  final Color elementGray = const Color(0xFF31353A);
  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFF9BA3AA);
  final Color accentMint = const Color(0xFFC2E5CD);
  final Color accentPeach = const Color(0xFFFFB4A9);

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';

      final file = File('$folderPath/frequent_schedule.json');

      if (await file.exists()) {
        final String content = await file.readAsString();
        final List<dynamic> decodedData = jsonDecode(content);
        setState(() {
          _routineTasks = decodedData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading routine: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRoutine() async {
    final directory = await getApplicationDocumentsDirectory();
    final String folderPath = '${directory.path}/flow';
    final Directory myFolder = Directory(folderPath);

    if (!await myFolder.exists()) {
      await myFolder.create(recursive: true);
    }
    final file = File('$folderPath/frequent_schedule.json');
    _routineTasks.sort((a, b) => a['start'].compareTo(b['start']));
    await file.writeAsString(jsonEncode(_routineTasks));
  }

  // --- DEEP SYNC: DELETION ---
  Future<void> _deleteTaskFromAllDays(String taskNameToDelete) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final Directory flowDir = Directory('${directory.path}/flow');

      if (!await flowDir.exists()) return;

      final List<FileSystemEntity> files = flowDir.listSync();

      for (var file in files) {
        String fileName = file.uri.pathSegments.last;
        if (file is File && fileName.startsWith('daily_') && fileName.endsWith('.json')) {
          List<dynamic> dayTasks = jsonDecode(await file.readAsString());
          
          int originalLength = dayTasks.length;
          // Remove the task if the name matches
          dayTasks.removeWhere((item) => item['task'] == taskNameToDelete);

          // Only rewrite the file if we actually deleted something from it
          if (dayTasks.length < originalLength) {
            await file.writeAsString(jsonEncode(dayTasks));
          }
        }
      }
    } catch (e) {
      debugPrint("Error deleting task deeply: $e");
    }
  }

  // --- DEEP SYNC: UPDATING ---
  Future<void> _updateTaskInAllDays(String oldName, String newName, String newStart, String newEnd) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final Directory flowDir = Directory('${directory.path}/flow');

      if (!await flowDir.exists()) return;

      final List<FileSystemEntity> files = flowDir.listSync();

      for (var file in files) {
        String fileName = file.uri.pathSegments.last;
        if (file is File && fileName.startsWith('daily_') && fileName.endsWith('.json')) {
          List<dynamic> dayTasks = jsonDecode(await file.readAsString());
          bool fileModified = false;

          for (var item in dayTasks) {
            if (item['task'] == oldName) {
              item['task'] = newName;
              item['start'] = newStart;
              item['end'] = newEnd;
              fileModified = true;
            }
          }

          if (fileModified) {
            // Re-sort the day's tasks chronologically just in case the time was changed
            dayTasks.sort((a, b) => a['start'].compareTo(b['start']));
            await file.writeAsString(jsonEncode(dayTasks));
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating task deeply: $e");
    }
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

  // --- UNIFIED ADD & EDIT DIALOG ---
  void _showTaskDialog({int? index}) {
    final bool isEdit = index != null;
    
    // Keep track of the old name in case they change it during an edit
    final String oldTaskName = isEdit ? _routineTasks[index]['task'] : "";

    final nameController = TextEditingController(
      text: isEdit ? _routineTasks[index]['task'] : "",
    );
    String startStr = isEdit ? _routineTasks[index]['start'] : "07:00";
    String endStr = isEdit ? _routineTasks[index]['end'] : "08:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: elementGray, width: 1),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isEdit ? "Edit Routine Task" : "New Routine Task",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Task Name",
                style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 16),
                cursorColor: accentMint,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: elementGray,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTimePickerColumn("Start Time", startStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: accentMint,
                              onPrimary: bgColor,
                              surface: cardBgColor,
                              onSurface: textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (t != null) {
                      setDialogState(
                        () => startStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                    }
                  }),
                  const SizedBox(width: 16),
                  _buildTimePickerColumn("End Time", endStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: accentMint,
                              onPrimary: bgColor,
                              surface: cardBgColor,
                              onSurface: textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (t != null) {
                      setDialogState(
                        () => endStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                    }
                  }),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentMint,
                      foregroundColor: bgColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        String newName = nameController.text.trim();
                        
                        setState(() {
                          if (isEdit) {
                            _routineTasks[index] = {
                              "task": newName,
                              "start": startStr,
                              "end": endStr,
                            };
                          } else {
                            _routineTasks.add({
                              "task": newName,
                              "start": startStr,
                              "end": endStr,
                            });
                          }
                        });
                        
                        await _saveRoutine();
                        
                        // If it's an edit, trigger the Deep Sync to update all files!
                        if (isEdit) {
                          _updateTaskInAllDays(oldTaskName, newName, startStr, endStr);
                        }
                        
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: Text(
                      isEdit ? "Save Changes" : "Add to Routine",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 24),
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
                          "Blueprint",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: accentMint))
                        : _routineTasks.isEmpty
                            ? Center(
                                child: Text("No routine set yet.", style: TextStyle(color: textSecondary, fontSize: 16)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: _routineTasks.length,
                                itemBuilder: (context, index) => _buildScheduleCard(_routineTasks[index], index),
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF000000), 
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.repeat, () {}, isSelected: true), 
                  _addIcon(() => Navigator.pushReplacement(context, _fadeRoute(const TasksPage()))),
                  _navIcon(Icons.insights, () => Navigator.pushReplacement(context, _fadeRoute(const ProgressPage()))),
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          backgroundColor: elementGray,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () => _showTaskDialog(), 
          child: Icon(Icons.add, color: accentMint, size: 28), 
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: elementGray, shape: BoxShape.circle),
            child: Icon(Icons.loop_rounded, color: accentMint, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['task'],
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${task['start']} - ${task['end']}",
                  style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: textSecondary),
                onPressed: () => _showTaskDialog(index: index), 
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: accentPeach), 
                onPressed: () {
                  String taskToDelete = _routineTasks[index]['task'];
                  
                  setState(() => _routineTasks.removeAt(index));
                  _saveRoutine();
                  
                  // Trigger Deep Sync Delete!
                  _deleteTaskFromAllDays(taskToDelete);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, VoidCallback onTap, {bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: elementGray,
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

  Widget _buildTimePickerColumn(String label, String timeVal, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: elementGray, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(
                timeVal,
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}