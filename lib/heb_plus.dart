import 'package:flutter/material.dart';
import 'heb_plu_flashcards.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper to load persisted struggled PLUs (name|plu strings)
Future<List<Map<String, String>>> _loadPersistedStruggledPlu() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('struggledPlu') ?? [];
  final result = <Map<String, String>>[];
  for (var item in list) {
    final parts = item.split('|');
    if (parts.length == 2) result.add({'name': parts[0], 'plu': parts[1]});
  }
  return result;
}

class HebPlusPage extends StatefulWidget {
  const HebPlusPage({Key? key}) : super(key: key);

  @override
  State<HebPlusPage> createState() => _HebPlusPageState();
}

class _HebPlusPageState extends State<HebPlusPage> {
  List<Map<String, String>> _pluList = [];
  bool _csvLoaded = false;
  @override
  void initState() {
    super.initState();
    _loadCsv();
  }

  Future<void> _loadCsv() async {
    final csvString = await DefaultAssetBundle.of(context).loadString('lib/assets/hebplus/HEBplus.csv');
    final lines = csvString.split('\n');
    final items = <Map<String, String>>[];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length >= 2) {
        items.add({"name": parts[0].replaceAll('"', ''), "plu": parts[1]});
      }
    }
    setState(() {
      _pluList = items;
      _csvLoaded = true;
    });
  }
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pluController = TextEditingController();
  int? _editingIndex;

  void _addOrUpdatePLU() {
    final name = _nameController.text.trim();
    final plu = _pluController.text.trim();
    if (name.isEmpty || plu.isEmpty) return;
    setState(() {
      if (_editingIndex == null) {
        _pluList.add({"name": name, "plu": plu});
      } else {
        _pluList[_editingIndex!] = {"name": name, "plu": plu};
        _editingIndex = null;
      }
      _nameController.clear();
      _pluController.clear();
    });
  }

  void _editPLU(int index) {
    setState(() {
      _nameController.text = _pluList[index]["name"]!;
      _pluController.text = _pluList[index]["plu"]!;
      _editingIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HEB PLU's"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shared button style for the top action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HebPluFlashcardsPage()),
                  );
                },
                child: const Text("Practice PLU's"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final items = await _loadPersistedStruggledPlu();
                  if (items.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('No difficult PLUs'),
                        content: const Text('You have no saved difficult PLUs to study.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                    return;
                  }
                  // Shuffle and take up to 8 items for a limited study session
                  items.shuffle();
                  final selected = items.length > 8 ? items.sublist(0, 8) : items;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HebPluFlashcardsPage(initialFlashcards: selected)),
                  );
                },
                child: const Text('Study Difficult PLUs'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.orange,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final items = await _loadPersistedStruggledPlu();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Difficult PLUs'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: items.isEmpty
                            ? const Text('No difficult PLUs saved yet.')
                            : ListView(
                                shrinkWrap: true,
                                children: items
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
                child: const Text('View Difficult PLUs'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Manage PLUs'),
              subtitle: const Text('Add or edit produce and PLU'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Produce Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pluController,
                        decoration: const InputDecoration(labelText: 'PLU'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _addOrUpdatePLU,
                          child: Text(_editingIndex == null ? 'Add' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !_csvLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _pluList.length,
                      itemBuilder: (context, index) {
                        final item = _pluList[index];
                        return ListTile(
                          title: Text(item["name"] ?? ''),
                          subtitle: Text('PLU: ${item["plu"] ?? ''}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
