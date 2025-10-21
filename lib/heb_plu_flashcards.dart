import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HebPluFlashcardsPage extends StatefulWidget {
  final List<Map<String, String>>? initialFlashcards;
  const HebPluFlashcardsPage({super.key, this.initialFlashcards});

  @override
  State<HebPluFlashcardsPage> createState() => _HebPluFlashcardsPageState();
}

class _HebPluFlashcardsPageState extends State<HebPluFlashcardsPage> {
  final List<Map<String, String>> _flashcards = [];
  // persisted struggled PLUs (saved between sessions)
  final List<Map<String, String>> _struggledPlu = [];
  // struggled PLUs for this session only
  final List<Map<String, String>> _sessionStruggledPlu = [];
  // Per-instance runtime state (reset when entering the page)
  int _hintLength = 0;
  int _score = 0;
  bool _finished = false;
  // These fields are populated in _loadCsv and intentionally kept for future use.
  // ignore: unused_field
  List<Map<String, String>> _csvItems = [];
  // ignore: unused_field
  bool _csvLoaded = false;
  @override
  void initState() {
    super.initState();
    // If initial flashcards were provided (study mode), use them; otherwise load CSV
    if (widget.initialFlashcards != null && widget.initialFlashcards!.isNotEmpty) {
      _flashcards.clear();
      _flashcards.addAll(widget.initialFlashcards!);
      _currentIndex = 0;
      _csvLoaded = true;
    } else {
      _loadCsv();
    }
    _loadStruggledPlu();
  }

  // Persistence helpers
  Future<void> _loadStruggledPlu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('struggledPlu') ?? [];
      setState(() {
        _struggledPlu.clear();
        for (var s in list) {
          final parts = s.split('|');
          if (parts.length == 2) {
            _struggledPlu.add({'name': parts[0], 'plu': parts[1]});
          }
        }
      });
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _saveStruggledPlu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _struggledPlu.map((e) => '${e['name']}|${e['plu']}').toList();
      await prefs.setStringList('struggledPlu', list);
    } catch (e) {
      // ignore
    }
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
    final correctPlu = _flashcards[_currentIndex]['plu'];
    final currentCard = _flashcards[_currentIndex];
    if (userInput == correctPlu) {
      setState(() {
        _feedback = null;
        // only count correct if no hint was used
        if (_hintLength == 0) {
          _score++;
          // If the user got this correct without a hint, remove it from the
          // session and persisted struggled lists (they've mastered it).
          _sessionStruggledPlu.removeWhere((e) => e['plu'] == currentCard['plu']);
          final before = _struggledPlu.length;
          _struggledPlu.removeWhere((e) => e['plu'] == currentCard['plu']);
          if (_struggledPlu.length != before) {
            _saveStruggledPlu();
          }
        } else {
          // used a hint: record as struggled
          if (!_sessionStruggledPlu.any((e) => e['plu'] == currentCard['plu'])) {
            _sessionStruggledPlu.add(currentCard);
          }
          if (!_struggledPlu.any((e) => e['plu'] == currentCard['plu'])) {
            _struggledPlu.add(currentCard);
            _saveStruggledPlu();
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hintLength == 0 ? 'Correct!' : 'Correct (used hint)'),
          backgroundColor: _hintLength == 0 ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _nextCard();
      });
    } else {
      setState(() {
        _feedback = 'Incorrect. Try again.';
        // wrong answer: record as struggled
        if (!_sessionStruggledPlu.any((e) => e['plu'] == currentCard['plu'])) {
          _sessionStruggledPlu.add(currentCard);
        }
        if (!_struggledPlu.any((e) => e['plu'] == currentCard['plu'])) {
          _struggledPlu.add(currentCard);
          _saveStruggledPlu();
        }
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

  // Helper to build a small numeric button for the keypad
  Widget _numButton(String label) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            setState(() {
              final text = _controller.text;
              _controller.text = text + label;
              _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
            });
          },
          child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final card = _flashcards.isNotEmpty ? _flashcards[_currentIndex] : {"name": "", "plu": ""};
      return Scaffold(
        appBar: AppBar(
          title: const Text("Practice"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _finished
              ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          'You got $_score out of ${_flashcards.length} correct!',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Session-specific struggled PLUs
                      if (_sessionStruggledPlu.isNotEmpty) ...[
                        const Text(
                          'PLUs you struggled with this session:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ..._sessionStruggledPlu.map((item) => Text(
                              '${item['name']} (PLU: ${item['plu']})',
                              style: const TextStyle(fontSize: 18, color: Colors.red),
                            )),
                        const SizedBox(height: 16),
                      ],
                      // Button to show full persisted difficult PLUs
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          // show dialog with persisted struggled PLUs
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('All Difficult PLUs'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: _struggledPlu.isEmpty
                                    ? const Text('No difficult PLUs saved yet.')
                                    : ListView(
                                        shrinkWrap: true,
                                        children: _struggledPlu
                                            .map((e) => ListTile(
                                                  title: Text(e['name'] ?? ''),
                                                  subtitle: Text('PLU: ${e['plu'] ?? ''}'),
                                                ))
                                            .toList(),
                                      ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                        child: const Text('Show all difficult PLUs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          setState(() {
                            _score = 0;
                            _finished = false;
                            _currentIndex = 0;
                            _controller.clear();
                            _feedback = null;
                            _loadCsv();
                            _sessionStruggledPlu.clear();
                          });
                        },
                        child: const Text('Practice Again', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Return to HEB PLU\'s Page', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
              : Padding(
                  // Removed extra bottom padding to prevent content from being pushed up when hint appears
                  padding: const EdgeInsets.only(bottom: 0.0),
                  child: SingleChildScrollView(
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
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: _finished ? null : SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Controls above the numeric keypad: Hint (left) and Clear (right)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                setState(() {
                                  final plu = card["plu"] ?? "";
                                  if (_hintLength < plu.length) {
                                    _hintLength++;
                                  }
                                });
                              },
                              child: const Text('Hint', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 234, 182, 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.clear();
                                  _controller.selection = const TextSelection.collapsed(offset: 0);
                                });
                              },
                              child: const Text('Clear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Top row: 7 8 9
                    Row(
                      children: [
                        _numButton('7'),
                        const SizedBox(width: 8),
                        _numButton('8'),
                        const SizedBox(width: 8),
                        _numButton('9'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Middle row: 4 5 6
                    Row(
                      children: [
                        _numButton('4'),
                        const SizedBox(width: 8),
                        _numButton('5'),
                        const SizedBox(width: 8),
                        _numButton('6'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bottom row: 1 2 3 (smaller numbered buttons on the bottom as requested)
                    Row(
                      children: [
                        _numButton('1'),
                        const SizedBox(width: 8),
                        _numButton('2'),
                        const SizedBox(width: 8),
                        _numButton('3'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row with 0 and X buttons
                    Row(
                      children: [
                        // '0' button - twice the width of 'X'
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                // Append '0' to the input field
                                setState(() {
                                  final text = _controller.text;
                                  _controller.text = text + '0';
                                  _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                                });
                              },
                              child: const Text(
                                '0',
                                style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 'X' button - half the width of '0'
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 234, 182, 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                // Delete last character from input field
                                setState(() {
                                  final text = _controller.text;
                                  if (text.isNotEmpty) {
                                    _controller.text = text.substring(0, text.length - 1);
                                    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                                  }
                                });
                              },
                              child: const Text(
                                'X',
                                style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _checkAnswer,
                    child: const Text(
                      'Check',
                      style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // small gap below Check to act as divider before safe area
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    } catch (e, st) {
      // Prevent the widget tree from crashing; show a simple error UI and log to console
      // ignore: avoid_print
      print('Build error in HebPluFlashcardsPage: $e\n$st');
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('An unexpected error occurred while building this screen.'),
                const SizedBox(height: 8),
                Text(e.toString(), style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Try a rebuild
                    setState(() {});
                  },
                  child: const Text('Try Again'),
                )
              ],
            ),
          ),
        ),
      );
    }
  }
}
