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

  final Color primaryDark = const Color(0xFF001B3D);
  final Color cardColor = const Color(0xFF1D3D5E);

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
      debugPrint('Created new folder at : $folderPath');
    }
    final file = File('$folderPath/frequent_schedule.json');
    _routineTasks.sort((a, b) => a['start'].compareTo(b['start']));
    await file.writeAsString(jsonEncode(_routineTasks));
  }

  // --- UNIFIED ADD & EDIT DIALOG ---
  void _showTaskDialog({int? index}) {
    final bool isEdit = index != null;

    final nameController = TextEditingController(
      text: isEdit ? _routineTasks[index]['task'] : "",
    );
    String startStr = isEdit ? _routineTasks[index]['start'] : "07:00";
    String endStr = isEdit ? _routineTasks[index]['end'] : "08:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2C4364),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isEdit ? "Edit Task" : "Add Task",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Task Name",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
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
                    );
                    if (t != null)
                      setDialogState(
                        () => startStr =
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                  }),
                  const SizedBox(width: 20),
                  _buildTimePickerColumn("End Time", endStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null)
                      setDialogState(
                        () => endStr =
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                  }),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        setState(() {
                          if (isEdit) {
                            // Update existing
                            _routineTasks[index] = {
                              "task": nameController.text.trim(),
                              "start": startStr,
                              "end": endStr,
                            };
                          } else {
                            // Add new
                            _routineTasks.add({
                              "task": nameController.text.trim(),
                              "start": startStr,
                              "end": endStr,
                            });
                          }
                        });
                        _saveRoutine();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
      backgroundColor: primaryDark,
      body: Stack(
        children: [
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (Route<dynamic> route) =>
                                false, // This destroys all other routes in the background
                          );
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Frequent Schedule",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: _routineTasks.length,
                            itemBuilder: (context, index) =>
                                _buildScheduleCard(_routineTasks[index], index),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // FIXED NAVBAR
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.repeat, () {}, isSelected: true),
                  _midIcon(
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TasksPage(),
                      ),
                    ),
                  ),
                  _navIcon(
                    Icons.insights,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: FloatingActionButton(
          backgroundColor: cardColor,
          elevation: 10,
          onPressed: () =>
              _showTaskDialog(), // Calls dialog as "Add" (index is null)
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2641),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.list_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['task'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${task['start']} - ${task['end']}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Actions Row (Edit & Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                onPressed: () =>
                    _showTaskDialog(index: index), // Calls dialog as "Edit"
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                onPressed: () {
                  setState(() => _routineTasks.removeAt(index));
                  _saveRoutine();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navbar icons fixed to show perfect circular splash
  Widget _navIcon(
    IconData icon,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: isSelected
              ? Colors.white24
              : const Color(0xFF1D3D5E),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _midIcon(VoidCallback onTap) {
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

  Widget _buildTimePickerColumn(
    String label,
    String timeVal,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Text(
                timeVal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
