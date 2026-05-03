import 'package:app/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'repeats_page.dart';
import 'progress_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _todaysTasks = [];
  bool _isLoading = true;
  List<String> _frequentTaskNames = [];

  final Color primaryDark = const Color(0xFF001B3D);
  final Color cardColor = const Color(0xFF1D3D5E);
  final Color modalBg = const Color(0xFF2C4364);
  final Color tealAccent = const Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _loadData(_selectedDate);
  }

  Future<void> _loadData(DateTime date) async {
    setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();
    final String folderPath = '${directory.path}/flow';
    final String dateKey = DateFormat('yyyy-MM-dd').format(date);

    final dailyFile = File('$folderPath/daily_$dateKey.json');
    final bpFile = File('$folderPath/frequent_schedule.json');

    List<dynamic> bpTasks = [];
    _frequentTaskNames = [];

    // 1. ALWAYS load the latest Frequent Schedule (The Blueprint)
    if (await bpFile.exists()) {
      bpTasks = jsonDecode(await bpFile.readAsString());
      _frequentTaskNames = bpTasks.map((e) => e['task'].toString()).toList();
    }

    if (await dailyFile.exists()) {
      List<Map<String, dynamic>> savedTasks = List<Map<String, dynamic>>.from(
        jsonDecode(await dailyFile.readAsString()),
      );

      // --- THE SYNC ENGINE ---

      for (var bpTask in bpTasks) {
        bool exists = savedTasks.any((t) => t['task'] == bpTask['task']);
        if (!exists) {
          savedTasks.add({
            "task": bpTask['task'],
            "start": bpTask['start'],
            "end": bpTask['end'],
            "done": 0,
            "duration_label": "today",
          });
        }
      }

      // B. Update times for existing frequent tasks (if edited in RepeatsPage)
      for (var task in savedTasks) {
        if (_frequentTaskNames.contains(task['task'])) {
          var updatedBp = bpTasks.firstWhere(
            (e) => e['task'] == task['task'],
            orElse: () => null,
          );
          if (updatedBp != null) {
            task['start'] = updatedBp['start'];
            task['end'] = updatedBp['end'];
          }
        }
      }

      // C. Sort the list by start time so the schedule stays chronological
      savedTasks.sort((a, b) => a['start'].compareTo(b['start']));

      _todaysTasks = savedTasks;

      // D. Save the newly synced list back to today's file silently
      await dailyFile.writeAsString(jsonEncode(_todaysTasks));
    } else {
      // 2. If it's a new day, initialize it fresh from the blueprint
      _todaysTasks = bpTasks
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

      // Sort the initial load as well
      _todaysTasks.sort((a, b) => a['start'].compareTo(b['start']));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateCurrentDaySave() async {
    final directory = await getApplicationDocumentsDirectory();
    final String folderPath = '${directory.path}/flow';

    final String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final file = File('$folderPath/daily_$dateKey.json');
    await file.writeAsString(jsonEncode(_todaysTasks));
  }

  Future<void> _saveTaskToDate(
    String dateKey,
    Map<String, dynamic> newTask,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/flow';

      final Directory flowFolder = Directory(folderPath);
      if (!await flowFolder.exists()) {
        await flowFolder.create(recursive: true);
      }

      final file = File('$folderPath/daily_$dateKey.json');
      List<Map<String, dynamic>> tasks = [];

      if (await file.exists()) {
        final String content = await file.readAsString();
        tasks = List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        final bpFile = File('$folderPath/frequent_schedule.json');
        if (await bpFile.exists()) {
          List<dynamic> bp = jsonDecode(await bpFile.readAsString());
          tasks = bp
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
        }
      }

      tasks.add(newTask);
      await file.writeAsString(jsonEncode(tasks));

      debugPrint("Task added to $dateKey irrespective of source.");
    } catch (e) {
      debugPrint("Error saving task: $e");
    }
  }

  // --- MONTH & YEAR PICKER ---

  void _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: tealAccent,
              onPrimary: Colors.white,
              surface: modalBg,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: modalBg,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData(picked);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // TOP BACK BAR
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
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "My Tasks",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 15),
                // MONTH SELECTOR
                GestureDetector(
                  onTap: _showMonthPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildHorizontalCalendar(),
                const SizedBox(height: 30),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
                          itemCount: _todaysTasks.length,
                          itemBuilder: (context, index) =>
                              _buildTaskCard(_todaysTasks[index], index),
                        ),
                ),
              ],
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
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(
                    Icons.repeat,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RepeatsPage(),
                      ),
                    ),
                  ),
                  _midIcon(() {}), // Current Page
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
        padding: const EdgeInsets.only(bottom: 140),
        child: FloatingActionButton(
          backgroundColor: cardColor,
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 31,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          DateTime date = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            1,
          ).add(Duration(days: index));
          bool isSel =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadData(date);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSel ? Colors.grey[400] : cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSel ? primaryDark : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSel ? primaryDark : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item, int index) {
    bool isDone = item['done'] == 1;
    bool isFrequent = _frequentTaskNames.contains(item['task']);
    final double radius = 24.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isFrequent
            ? const Color(0xFF2E4B5E)
            : (isDone ? cardColor.withOpacity(0.5) : cardColor),
        borderRadius: BorderRadius.circular(radius),
        border: isFrequent ? Border.all(color: Colors.white10, width: 1) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _todaysTasks[index]['done'] = isDone ? 0 : 1);
              _updateCurrentDaySave();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ListTile(
                leading: Icon(
                  isDone
                      ? Icons.check_circle
                      : (isFrequent ? Icons.replay_rounded : Icons.list_alt),
                  color: Colors.white,
                  size: 28,
                ),
                title: Text(
                  item['task'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  "${item['start']} - ${item['end']} • ${item['duration_label'] ?? 'today'}",
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: isFrequent
                    ? const Icon(
                        Icons.lock_outline,
                        color: Colors.white24,
                        size: 20,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white54,
                            ),
                            onPressed: () => _showEditTaskDialog(index),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() => _todaysTasks.removeAt(index));
                              _updateCurrentDaySave();
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- NAVBAR HELPERS ---

  Widget _navIcon(
    IconData icon,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
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
    return GestureDetector(
      onTap: onTap,
      child: const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white24,
        child: Icon(Icons.add, color: Colors.white, size: 40),
      ),
    );
  }

  // --- ADD TASK DIALOG ---

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: "1");
    String startStr = "09:00";
    String endStr = "10:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: modalBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Add Task",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Task Name", style: TextStyle(color: Colors.white70)),
              _buildDialogField(nameController),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildTimeCol("Start Time", startStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null)
                      setDialogState(() => startStr = t.format(context));
                  }),
                  const SizedBox(width: 15),
                  _buildTimeCol("End Time", endStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null)
                      setDialogState(() => endStr = t.format(context));
                  }),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Duration ( days )",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(
                width: 100,
                child: _buildDialogField(durationController, isNum: true),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealAccent,
                    fixedSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      int days = int.tryParse(durationController.text) ?? 1;
                      for (int i = 0; i < days; i++) {
                        DateTime target = _selectedDate.add(Duration(days: i));
                        String label = (days - i - 1) == 0
                            ? "today"
                            : "${days - i - 1} days remaining";
                        await _saveTaskToDate(
                          DateFormat('yyyy-MM-dd').format(target),
                          {
                            "task": nameController.text.trim(),
                            "start": startStr,
                            "end": endStr,
                            "done": 0,
                            "duration_label": label,
                          },
                        );
                      }
                      _loadData(_selectedDate);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EDIT TASK DIALOG ---

  void _showEditTaskDialog(int index) {
    final task = _todaysTasks[index];
    final nameController = TextEditingController(text: task['task']);
    String startStr = task['start'];
    String endStr = task['end'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: modalBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Edit Task",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Task Name", style: TextStyle(color: Colors.white70)),
              _buildDialogField(nameController),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildTimeCol("Start Time", startStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null)
                      setDialogState(() => startStr = t.format(context));
                  }),
                  const SizedBox(width: 15),
                  _buildTimeCol("End Time", endStr, () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null)
                      setDialogState(() => endStr = t.format(context));
                  }),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealAccent,
                    fixedSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _todaysTasks[index]['task'] = nameController.text
                            .trim();
                        _todaysTasks[index]['start'] = startStr;
                        _todaysTasks[index]['end'] = endStr;
                      });
                      _updateCurrentDaySave();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller, {
    bool isNum = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTimeCol(String label, String val, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                val,
                style: const TextStyle(
                  color: Colors.white,
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
