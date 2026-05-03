import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class RepeatsPage extends StatefulWidget {
  const RepeatsPage({Key? key}) : super(key: key);

  @override
  State<RepeatsPage> createState() => _RepeatsPageState();
}

class _RepeatsPageState extends State<RepeatsPage> {
  List<Map<String, dynamic>> _routineTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  // --- STORAGE LOGIC ---

  Future<void> _loadRoutine() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/routine_blueprint.json');

    if (await file.exists()) {
      String data = await file.readAsString();
      List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _routineTasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveRoutine() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/routine_blueprint.json');
    // Sort chronologically before saving
    _routineTasks.sort((a, b) => a['start'].compareTo(b['start']));
    await file.writeAsString(jsonEncode(_routineTasks));
  }

  // --- MODAL & UI LOGIC ---
void _showAddModal() {
  final TextEditingController nameController = TextEditingController();
  
  // Default strings for time
  String startTimeStr = "07:00";
  String endTimeStr = "08:00";

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder( // Added to ensure time updates show in dialog
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "New Routine Task", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E212D)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. TASK NAME INPUT
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.black), // FORCE BLACK TEXT
              decoration: InputDecoration(
                hintText: "Task Name",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. TIME SELECTORS
            Row(
              children: [
                // START TIME
                Expanded(
                  child: _buildSimpleTimeButton(
                    label: "Start", 
                    timeValue: startTimeStr, 
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context, 
                        initialTime: const TimeOfDay(hour: 7, minute: 0)
                      );
                      if (t != null) {
                        setDialogState(() {
                          startTimeStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    }
                  ),
                ),
                const SizedBox(width: 10),
                // END TIME
                Expanded(
                  child: _buildSimpleTimeButton(
                    label: "End", 
                    timeValue: endTimeStr, 
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context, 
                        initialTime: const TimeOfDay(hour: 8, minute: 0)
                      );
                      if (t != null) {
                        setDialogState(() {
                          endTimeStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E212D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _routineTasks.add({
                    "task": nameController.text.trim(),
                    "start": startTimeStr,
                    "end": endTimeStr,
                  });
                });
                _saveRoutine(); // Writes to routine_blueprint.json
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    ),
  );
}

// Simple helper for the time buttons inside the dialog
Widget _buildSimpleTimeButton({required String label, required String timeValue, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(timeValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
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
        title: const Text("Repeats", style: TextStyle(color: Color(0xFF1E212D), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _routineTasks.isEmpty
            ? Center(child: Text("No repeated tasks added.", style: TextStyle(color: Colors.grey[400])))
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _routineTasks.length,
                itemBuilder: (context, index) {
                  final item = _routineTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), offset: const Offset(0, 8), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.sync_rounded, color: Colors.orangeAccent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['task'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                Text("${item['start']} - ${item['end']}", style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _routineTasks.removeAt(index));
                              _saveRoutine();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}