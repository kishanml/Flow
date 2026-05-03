import 'package:app/pages/progress_page.dart';
import 'package:app/pages/repeats_page.dart';
import 'package:app/pages/tasks_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Helper widget to build identical, uniformly sized premium cards
  Widget _buildPremiumCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Ensures all cards stretch to the same width
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Very soft, premium shadow
              // blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // Using a Row layout to make these identical vertical list items look sleek
        child: Row(
          children: [
            // Icon with tinted background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142), 
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), 
      
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                
                // 1. SINGLE LINE HEADER (No profile icon)
                const Text(
                  "Welcome Kishan !",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E212D),
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 40),

                // 2. UNIFORM CARDS
             

                _buildPremiumCard(
                  context: context,
                  title: "Repeats",
                  subtitle: "Repeated Schedule",
                  icon: Icons.sync_rounded,
                  iconColor: Colors.orangeAccent,
                  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RepeatsPage()),
  ),
                ),

                const SizedBox(height: 20),

                   _buildPremiumCard(
                  context: context,
                  title: "Tasks",
                  subtitle: "Daily TODOs",
                  icon: Icons.task_alt_rounded,
                  iconColor: Colors.blueAccent,
                  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const TasksPage()),
  ),
                ),
                

                const SizedBox(height: 20),

                _buildPremiumCard(
                  context: context,
                  title: "Progress",
                  subtitle: "Consistency Meter",
                  icon: Icons.insights_rounded,
                  iconColor: Colors.purple,
                  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ProgressPage()),
                ),),
                
                const SizedBox(height: 100), // Buffer for the bottom navigation bar
              ],
            ),
          ),
        ),
      ),

      // 3. CENTRAL HOME NAVIGATOR
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1E212D), 
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
          ),
          onPressed: () {
            // Already home!
          },
          child: const Icon(Icons.home_filled, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 250, 244, 244),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0, 
        child: const SizedBox(height: 60), 
      ),
    );
  }
}