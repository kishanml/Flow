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

  // --- NEW: Scroll Controller to auto-focus the current day ---
  late ScrollController _calendarController;

  // --- THEME COLORS ---
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

    // Calculate initial scroll position to center the current day.
    // Each date item is 70px wide + 16px horizontal margin = 86px total width.
    // Subtracting ~130 offsets the list so the current day sits in the middle of the screen.
    double initialOffset = (_selectedDate.day - 1) * 86.0 - 130;
    if (initialOffset < 0) initialOffset = 0;

    _calendarController = ScrollController(initialScrollOffset: initialOffset);

    _loadData(_selectedDate);
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
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

  Future<void> _loadData(DateTime date) async {
    setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();
    final String folderPath = '${directory.path}/flow';
    final String dateKey = DateFormat('yyyy-MM-dd').format(date);

    final dailyFile = File('$folderPath/daily_$dateKey.json');
    final bpFile = File('$folderPath/frequent_schedule.json');

    List<dynamic> bpTasks = [];
    _frequentTaskNames = [];

    if (await bpFile.exists()) {
      bpTasks = jsonDecode(await bpFile.readAsString());
      _frequentTaskNames = bpTasks.map((e) => e['task'].toString()).toList();
    }

    if (await dailyFile.exists()) {
      List<Map<String, dynamic>> savedTasks = List<Map<String, dynamic>>.from(
        jsonDecode(await dailyFile.readAsString()),
      );

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

      savedTasks.sort((a, b) => a['start'].compareTo(b['start']));
      _todaysTasks = savedTasks;
      await dailyFile.writeAsString(jsonEncode(_todaysTasks));
    } else {
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
    // Removed try/catch so the error bubbles up to the UI
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
      // Safely parse the list to prevent Type Cast errors in Release mode
      final List<dynamic> decoded = jsonDecode(content);
      tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
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
  }

  void _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentMint,
              onPrimary: bgColor,
              surface: cardBgColor,
              onSurface: textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: accentMint),
            ),
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

      // Auto-scroll the calendar to the newly picked date smoothly
      double newOffset = (picked.day - 1) * 86.0 - 130;
      if (newOffset < 0) newOffset = 0;
      _calendarController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // TOP BACK BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
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
                          "My Tasks",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
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
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: textSecondary,
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
                      ? Center(
                          child: CircularProgressIndicator(color: accentMint),
                        )
                      : _todaysTasks.isEmpty
                      ? Center(
                          child: Text(
                            "No tasks for this day.",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 16,
                            ),
                          ),
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
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.repeat, () => Navigator.pushReplacement(context, _fadeRoute(const RepeatsPage()))),
                  
                  // UPDATED: Now redirects to HomePage
                  _midIcon(() => Navigator.pushReplacement(context, _fadeRoute(const HomePage()))), 
                  
                  _navIcon(Icons.insights, () => Navigator.pushReplacement(context, _fadeRoute(const ProgressPage()))),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          backgroundColor: elementGray,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onPressed: _showAddTaskDialog,
          child: Icon(Icons.add, color: accentMint, size: 30),
        ),
      ),
    );
  }

  // --- AUTO-SCROLLING HORIZONTAL CALENDAR ---
  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _calendarController, // Added the controller here!
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

              // Smoothly scroll the tapped date to the center
              double newOffset = (date.day - 1) * 86.0 - 130;
              if (newOffset < 0) newOffset = 0;
              _calendarController.animateTo(
                newOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSel ? accentMint : cardBgColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSel ? bgColor : textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSel ? bgColor.withOpacity(0.7) : textSecondary,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isFrequent ? surfaceColor : cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: isFrequent
            ? Border.all(color: accentMint.withOpacity(0.2), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _todaysTasks[index]['done'] = isDone ? 0 : 1);
              _updateCurrentDaySave();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: ListTile(
                leading: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : (isFrequent
                            ? Icons.loop_rounded
                            : Icons.circle_outlined),
                  color: isDone ? accentMint : textSecondary,
                  size: 28,
                ),
                title: Text(
                  item['task'],
                  style: TextStyle(
                    color: isDone ? textSecondary : textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${item['start']} - ${item['end']} • ${item['duration_label'] ?? 'today'}",
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
                trailing: isFrequent
                    ? Icon(
                        Icons.lock_outline,
                        color: textSecondary.withOpacity(0.5),
                        size: 20,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: textSecondary,
                            ),
                            onPressed: () => _showEditTaskDialog(index),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: accentPeach,
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
          backgroundColor: elementGray,
          child: Icon(icon, color: textSecondary),
        ),
      ),
    );
  }

  Widget _midIcon(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 35,
        backgroundColor: accentMint, 
      child: Icon(Icons.home_rounded, color: bgColor, size: 36),      ),
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentMint,
              onPrimary: bgColor,
              surface: cardBgColor,
              onSurface: textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: accentMint),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: "1");
    String startStr = "09:00";
    String endStr = "10:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: elementGray),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Add Task",
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
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDialogField(nameController),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTimeCol("Start Time", startStr, () async {
                    final t = await _pickTime(TimeOfDay.now());
                    if (t != null)
                      setDialogState(
                        () => startStr =
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                  }),
                  const SizedBox(width: 15),
                  _buildTimeCol("End Time", endStr, () async {
                    final t = await _pickTime(TimeOfDay.now());
                    if (t != null)
                      setDialogState(
                        () => endStr =
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Duration ( days )",
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 100,
                child: _buildDialogField(durationController, isNum: true),
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
                        try {
                          int days = int.tryParse(durationController.text) ?? 1;
                          for (int i = 0; i < days; i++) {
                            DateTime target = _selectedDate.add(Duration(days: i));
                            String label = (days - i - 1) == 0 ? "today" : "${days - i - 1} days remaining";
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
                          if (mounted) Navigator.pop(context);
                          
                        } catch (e) {
                          // --- SHOW THE ERROR ON SCREEN ---
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Save Error: $e", style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 5),
                              )
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
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

  void _showEditTaskDialog(int index) {
    final task = _todaysTasks[index];
    final nameController = TextEditingController(text: task['task']);
    String startStr = task['start'];
    String endStr = task['end'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: elementGray),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Edit Task",
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
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDialogField(nameController),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTimeCol("Start Time", startStr, () async {
                    final t = await _pickTime(TimeOfDay.now());
                    if (t != null)
                      setDialogState(
                        () => startStr =
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                      );
                  }),
                  const SizedBox(width: 15),
                  _buildTimeCol("End Time", endStr, () async {
                    final t = await _pickTime(TimeOfDay.now());
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
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        setState(() {
                          _todaysTasks[index]['task'] = nameController.text
                              .trim();
                          _todaysTasks[index]['start'] = startStr;
                          _todaysTasks[index]['end'] = endStr;
                        });
                        _updateCurrentDaySave();
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
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

  Widget _buildDialogField(
    TextEditingController controller, {
    bool isNum = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textPrimary, fontSize: 16),
      cursorColor: accentMint,
      decoration: InputDecoration(
        filled: true,
        fillColor: elementGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: elementGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                val,
                style: TextStyle(
                  color: textPrimary,
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
