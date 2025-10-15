import 'package:flutter/material.dart';

class HebPluFlashcardsPage extends StatefulWidget {
  const HebPluFlashcardsPage({Key? key}) : super(key: key);

  @override
  State<HebPluFlashcardsPage> createState() => _HebPluFlashcardsPageState();
}

class _HebPluFlashcardsPageState extends State<HebPluFlashcardsPage> {
  final List<Map<String, String>> _flashcards = [];
  List<Map<String, String>> _csvItems = [];
  bool _csvLoaded = false;
  @override
  void initState() {
    super.initState();
    _loadCsv();
  }

  Future<void> _loadCsv() async {
    // Load CSV from assets
    final csvString = await DefaultAssetBundle.of(context).loadString('lib/assets/hebplus/HEBplus.csv');
    final lines = csvString.split('\n');
    final items = <Map<String, String>>[];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length >= 2) {
        final name = parts[0].replaceAll('"', '').replaceAll(':', '').trim();
        final plu = parts[1].replaceAll(':', '').trim();
        items.add({"name": name, "plu": plu});
      }
    }
    // Pick 8 random items for flashcards
    items.shuffle();
    final selected = items.length >= 8 ? items.sublist(0, 8) : items;
    setState(() {
      _csvItems = items;
      _csvLoaded = true;
      _flashcards.clear();
      _flashcards.addAll(selected);
      _currentIndex = 0;
    });
  }
  int _currentIndex = 0;
  final TextEditingController _controller = TextEditingController();
  String? _feedback;

  void _checkAnswer() {
    final userInput = _controller.text.trim();
    final correctPlu = _flashcards[_currentIndex]["plu"];
    setState(() {
      if (userInput == correctPlu) {
        _feedback = "Correct!";
      } else {
        _feedback = "Incorrect. Try again.";
      }
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
      _controller.clear();
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _flashcards.isNotEmpty ? _flashcards[_currentIndex] : {"name": "", "plu": ""};
    return Scaffold(
      appBar: AppBar(
        title: const Text("HEB PLU Flashcards"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Produce: ${card["name"]}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter PLU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAnswer,
                child: const Text('Check'),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 16),
                Text(
                  _feedback!,
                  style: TextStyle(
                    color: _feedback == "Correct!" ? Colors.green : Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _nextCard,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
