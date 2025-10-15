import 'package:flutter/material.dart';
  int _hintLength = 0;
  int _score = 0;
  bool _finished = false;

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
    if (userInput == correctPlu) {
      setState(() {
        _feedback = null;
        _score++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correct!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _nextCard();
        }
      });
    } else {
      setState(() {
        _feedback = "Incorrect. Try again.";
      });
    }
  }

  void _nextCard() {
  _hintLength = 0;
    setState(() {
      if (_currentIndex + 1 >= _flashcards.length) {
        _finished = true;
      } else {
        _currentIndex++;
        _controller.clear();
        _feedback = null;
      }
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
        child: _finished
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You got $_score out of ${_flashcards.length} correct!',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _score = 0;
                        _finished = false;
                        _currentIndex = 0;
                        _controller.clear();
                        _feedback = null;
                        _loadCsv();
                      });
                    },
                    child: const Text('Practice Again'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Return to HEB PLU\'s Page'),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Produce: ${card["name"]}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (_hintLength > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                        child: Text(
                          'Hint: ${card["plu"]!.substring(0, _hintLength)}',
                          style: const TextStyle(fontSize: 20, color: Colors.blue),
                        ),
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
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final plu = card["plu"] ?? "";
                          if (_hintLength < plu.length) {
                            _hintLength++;
                          }
                        });
                      },
                      child: const Text('Hint'),
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
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                    ],
                    // ...existing code...
                  ],
                ),
              ),
      ),
    );
  }
}
