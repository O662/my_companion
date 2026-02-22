import 'package:flutter/material.dart';
import 'home.dart';
import 'tools.dart';
import 'personal.dart';

import 'bottom_nav_bar.dart';

class HealthPage extends StatefulWidget {
  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late TabController _tabController;

  // ── Exercise data ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _workouts = [
    {'name': 'Morning Run', 'category': 'Cardio', 'duration': '30 min', 'icon': Icons.directions_run, 'color': Colors.orange},
    {'name': 'Push-ups', 'category': 'Strength', 'duration': '15 min', 'icon': Icons.fitness_center, 'color': Colors.blue},
    {'name': 'Yoga Flow', 'category': 'Flexibility', 'duration': '45 min', 'icon': Icons.self_improvement, 'color': Colors.purple},
    {'name': 'Cycling', 'category': 'Cardio', 'duration': '60 min', 'icon': Icons.directions_bike, 'color': Colors.green},
    {'name': 'Weight Training', 'category': 'Strength', 'duration': '50 min', 'icon': Icons.fitness_center, 'color': Colors.red},
  ];

  // ── Metrics data ───────────────────────────────────────────────────────────
  // Sample health data - you can later connect to health APIs or Firebase
  final int _currentSteps = 8247;
  final int _goalSteps = 10000;
  final List<int> _weeklySteps = [7500, 9200, 6800, 8500, 7900, 9600, 8247];

  double get _progressPercentage => (_currentSteps / _goalSteps).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Don't navigate if we're already on this page
    if (index == 2) {
      return; // Already on health page
    }
    
    // Navigate to other pages
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ToolsPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PersonalPage()),
        );
        break;
    }
  }

  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    String selectedCategory = 'Cardio';
    final durationController = TextEditingController();

    final categories = ['Cardio', 'Strength', 'Flexibility', 'Sports', 'Other'];
    final categoryIcons = {
      'Cardio': Icons.directions_run,
      'Strength': Icons.fitness_center,
      'Flexibility': Icons.self_improvement,
      'Sports': Icons.sports,
      'Other': Icons.accessibility_new,
    };
    final categoryColors = {
      'Cardio': Colors.orange,
      'Strength': Colors.blue,
      'Flexibility': Colors.purple,
      'Sports': Colors.green,
      'Other': Colors.teal,
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Workout Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration (e.g. 30 min)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _workouts.add({
                      'name': nameController.text.trim(),
                      'category': selectedCategory,
                      'duration': durationController.text.trim().isEmpty
                          ? '--'
                          : durationController.text.trim(),
                      'icon': categoryIcons[selectedCategory],
                      'color': categoryColors[selectedCategory],
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Metrics'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Exercise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Metrics Tab ─────────────────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Steps Card with Chart
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_walk, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Daily Steps',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentSteps.toString(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'of $_goalSteps goal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _progressPercentage,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.green,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_progressPercentage * 100).toStringAsFixed(0)}% complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 120,
                              child: CustomPaint(
                                painter: BarChartPainter(
                                  data: _weeklySteps,
                                  maxValue: _goalSteps,
                                  barColor: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(flex: 2, child: Container()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                  .map((day) => Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Exercise Tab ────────────────────────────────────────────────────
          Column(
            children: [
              Expanded(
                child: _workouts.isEmpty
                    ? const Center(child: Text('No workouts yet. Add one!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _workouts.length,
                        itemBuilder: (context, index) {
                          final workout = _workouts[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (workout['color'] as Color).withOpacity(0.15),
                                child: Icon(
                                  workout['icon'] as IconData,
                                  color: workout['color'] as Color,
                                ),
                              ),
                              title: Text(
                                workout['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(workout['category']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    workout['duration'],
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () {
                                      setState(() => _workouts.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Workout'),
                    onPressed: _showAddWorkoutDialog,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Custom painter for bar chart
class BarChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final Color barColor;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (data.length * 2 - 1);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height;
      final left = i * barWidth * 2;
      final top = size.height - barHeight;

      paint.color = (i == data.length - 1) ? barColor : barColor.withOpacity(0.5);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}