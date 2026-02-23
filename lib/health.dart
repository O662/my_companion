import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'tools.dart';
import 'personal.dart';

import 'bottom_nav_bar.dart';

class HealthPage extends StatefulWidget {
  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  int _currentSteps = 0;
  final int _goalSteps = 10000;
  List<int> _weeklySteps = List.filled(7, 0);
  bool _isLoadingSteps = true;
  String _stepsError = '';

  double get _progressPercentage => (_currentSteps / _goalSteps).clamp(0.0, 1.0);

  static const String _consentKey = 'health_data_consent';
  // True while we're waiting for the user to return from the HC permission screen
  bool _waitingForHCPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _checkHealthConsent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from the Health Connect permission screen,
    // re-attempt the data read. HC registers the grant asynchronously so
    // we add a short delay before reading.
    if (state == AppLifecycleState.resumed && _waitingForHCPermission) {
      _waitingForHCPermission = false;
      Future.delayed(const Duration(milliseconds: 500), _readStepsData);
    }
  }

  Future<void> _checkHealthConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_consentKey);

    if (!mounted) return;

    if (stored == null) {
      // First time — show our in-app rationale dialog
      await _showHealthConsentDialog();
    } else if (stored == true) {
      _fetchSteps();
    } else {
      // User previously declined
      setState(() {
        _isLoadingSteps = false;
        _stepsError = 'health_denied';
      });
    }
  }

  Future<void> _showHealthConsentDialog() async {
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.green),
            SizedBox(width: 8),
            Text('Health Data Access'),
          ],
        ),
        content: const Text(
          'This app would like to read your step count from Health Connect '
          'to show your daily progress and weekly activity chart.\n\n'
          'Your data is only used within this app and is never shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    if (granted == true) {
      await prefs.setBool(_consentKey, true);
      _fetchSteps();
    } else {
      await prefs.setBool(_consentKey, false);
      if (!mounted) return;
      setState(() {
        _isLoadingSteps = false;
        _stepsError = 'health_denied';
      });
    }
  }

  Future<void> _fetchSteps() async {
    if (!mounted) return;

    // Health Connect is Android-only; skip on web/other platforms
    if (kIsWeb || !Platform.isAndroid) {
      setState(() {
        _isLoadingSteps = false;
        _stepsError = 'Step tracking is only available on Android.';
      });
      return;
    }

    setState(() {
      _isLoadingSteps = true;
      _stepsError = '';
    });

    try {
      // 1. Request ACTIVITY_RECOGNITION runtime permission
      final activityStatus = await Permission.activityRecognition.request();
      if (!mounted) return;

      if (activityStatus.isDenied || activityStatus.isPermanentlyDenied) {
        setState(() {
          _isLoadingSteps = false;
          _stepsError = activityStatus.isPermanentlyDenied
              ? 'Physical Activity permission is permanently denied. Please enable it in app Settings.'
              : 'Physical Activity permission denied.';
        });
        if (activityStatus.isPermanentlyDenied) openAppSettings();
        return;
      }

      final health = Health();
      await health.configure();
      final types = [HealthDataType.STEPS];

      // 2. Launch the Health Connect permission screen.
      // The app goes to background while the user interacts with HC.
      // We set a flag so didChangeAppLifecycleState can trigger the
      // data read when the user returns — by which time HC has
      // registered the grant.
      _waitingForHCPermission = true;
      await health.requestAuthorization(types);
      // If requestAuthorization returns without going to background
      // (permission already granted), the lifecycle won't fire — read now.
      if (_waitingForHCPermission) {
        _waitingForHCPermission = false;
        if (!mounted) return;
        await _readStepsData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSteps = false;
        _stepsError = 'Error: ${e.toString()}';
      });
    }
  }

  /// Removes duplicate Health Connect data points that arise when multiple
  /// sources (phone pedometer, Google Fit, Samsung Health, etc.) report the
  /// same steps for the same time window. Deduplication key is
  /// sourceId + dateFrom + dateTo + value.
  List<HealthDataPoint> _removeDuplicates(List<HealthDataPoint> points) {
    final seen = <String>{};
    return points.where((p) {
      final key =
          '${p.sourceId}|${p.dateFrom.millisecondsSinceEpoch}|${p.dateTo.millisecondsSinceEpoch}|${(p.value as NumericHealthValue).numericValue}';
      return seen.add(key);
    }).toList();
  }

  /// Reads step data from Health Connect. Called either directly (permission
  /// already granted) or from didChangeAppLifecycleState after the user
  /// returns from the HC permission screen.
  Future<void> _readStepsData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSteps = true;
      _stepsError = '';
    });

    try {
      final health = Health();
      await health.configure();
      final types = [HealthDataType.STEPS];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final rawTodayData = await health.getHealthDataFromTypes(
        types: types,
        startTime: todayStart,
        endTime: now,
      );
      if (!mounted) return;

      // Remove duplicate data points from multiple sources (e.g. phone
      // step counter + Google Fit + Samsung Health all reporting the same steps)
      final todayData = _removeDuplicates(rawTodayData);

      final todaySteps = todayData.fold<int>(0, (sum, point) {
        final val = (point.value as NumericHealthValue).numericValue;
        return sum + val.toInt();
      });

      final List<int> weekly = [];
      for (int i = 6; i >= 0; i--) {
        final dayStart = todayStart.subtract(Duration(days: i));
        final dayEnd = i == 0 ? now : dayStart.add(const Duration(days: 1));
        final rawDayData = await health.getHealthDataFromTypes(
          types: types,
          startTime: dayStart,
          endTime: dayEnd,
        );
        final dayData = _removeDuplicates(rawDayData);
        final daySteps = dayData.fold<int>(0, (sum, point) {
          final val = (point.value as NumericHealthValue).numericValue;
          return sum + val.toInt();
        });
        weekly.add(daySteps);
        if (!mounted) return;
      }

      setState(() {
        _currentSteps = todaySteps;
        _weeklySteps = weekly;
        _isLoadingSteps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSteps = false;
        _stepsError = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.green, size: 20),
                            tooltip: 'Refresh steps',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _fetchSteps,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_isLoadingSteps)
                        const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: Colors.green),
                        ))
                      else if (_stepsError.isNotEmpty)
                        Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _stepsError == 'health_denied'
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.health_and_safety_outlined,
                                        size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Health data access was denied.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      icon: const Icon(Icons.lock_open),
                                      label: const Text('Grant Access'),
                                      onPressed: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.remove(_consentKey);
                                        setState(() {
                                          _isLoadingSteps = true;
                                          _stepsError = '';
                                        });
                                        await _checkHealthConsent();
                                      },
                                    ),
                                  ],
                                )
                              : Text(
                                  _stepsError,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                ),
                        ))
                      else
                      Column(
                        children: [
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