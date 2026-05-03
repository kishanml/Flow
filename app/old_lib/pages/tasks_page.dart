import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _todaysTasks = [];
  List<String> _repeatedNames = []; // To track which tasks are "Repeats"
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasksForDate(_selectedDate);
  }

  String _getDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadTasksForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final directory = await getApplicationDocumentsDirectory();
    final String dateKey = _getDateKey(date);
    
    // 1. Load Blueprint names first to identify repeated tasks
    final blueprintFile = File('${directory.path}/routine_blueprint.json');
    if (await blueprintFile.exists()) {
      List<dynamic> blueprint = jsonDecode(await blueprintFile.readAsString());
      _repeatedNames = blueprint.map((e) => e['task'].toString()).toList();
    }

    // 2. Load Daily File
    final dailyFile = File('${directory.path}/daily_$dateKey.json');
    
    if (await dailyFile.exists()) {
      String data = await dailyFile.readAsString();
      setState(() {
        _todaysTasks = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    } else {
      // 3. Fallback to Blueprint if daily file doesn't exist yet
      if (await blueprintFile.exists()) {
        String data = await blueprintFile.readAsString();
        List<dynamic> blueprint = jsonDecode(data);
        setState(() {
          _todaysTasks = blueprint.map((e) => {
            "task": e['task'],
            "start": e['start'],
            "end": e['end'],
            "done": 0,
          }).toList();
        });
      } else {
        setState(() => _todaysTasks = []);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() async {
    final directory = await getApplicationDocumentsDirectory();
    final String dateKey = _getDateKey(_selectedDate);
    final dailyFile = File('${directory.path}/daily_$dateKey.json');
    await dailyFile.writeAsString(jsonEncode(_todaysTasks));
  }

  void _toggleTask(int index) {
    setState(() {
      _todaysTasks[index]['done'] = _todaysTasks[index]['done'] == 1 ? 0 : 1;
    });
    _saveTasks();
  }

  void _showAddTaskDialog() {
    final TextEditingController nameController = TextEditingController();
    String startStr = "09:00";
    String endStr = "10:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Add Extra Task", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E212D))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "What needs to be done?",
                  filled: true,
                  fillColor: const Color(0xFFF4F6F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildDialogTimeBtn("Start", startStr, () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setDialogState(() => startStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}");
                  }),
                  const SizedBox(width: 10),
                  _buildDialogTimeBtn("End", endStr, () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setDialogState(() => endStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}");
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E212D)),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _todaysTasks.add({
                      "task": nameController.text.trim(),
                      "start": startStr,
                      "end": endStr,
                      "done": 0,
                    });
                    _todaysTasks.sort((a, b) => a['start'].compareTo(b['start']));
                  });
                  _saveTasks();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add to Day", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTimeBtn(String label, String val, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
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
        title: const Text("Daily Tasks", style: TextStyle(color: Color(0xFF1E212D), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _selectedDate = picked;
                _loadTasksForDate(_selectedDate);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              DateFormat('EEEE, d MMM').format(_selectedDate),
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _todaysTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _todaysTasks.length,
                    itemBuilder: (context, index) {
                      final item = _todaysTasks[index];
                      bool isDone = item['done'] == 1;
                      bool isRepeated = _repeatedNames.contains(item['task']);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(item['task'] + index.toString()),
                          direction: isRepeated ? DismissDirection.none : DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              _todaysTasks.removeAt(index);
                            });
                            _saveTasks();
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          ),
                          child: GestureDetector(
                            onTap: () => _toggleTask(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDone ? Colors.white.withOpacity(0.6) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDone ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isDone ? Colors.greenAccent : Colors.grey[300],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['task'],
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                            color: isDone ? Colors.grey : const Color(0xFF1E212D),
                                          ),
                                        ),
                                        Text(
                                          "${item['start']} - ${item['end']}",
                                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRepeated)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        setState(() => _todaysTasks.removeAt(index));
                                        _saveTasks();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No tasks for this day.", style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Set up Repeats first"),
          )
        ],
      ),
    );
  }
}