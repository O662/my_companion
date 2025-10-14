import 'package:flutter/material.dart';
import 'heb_plu_flashcards.dart';

class HebPlusPage extends StatefulWidget {
  const HebPlusPage({Key? key}) : super(key: key);

  @override
  State<HebPlusPage> createState() => _HebPlusPageState();
}

class _HebPlusPageState extends State<HebPlusPage> {
  final List<Map<String, String>> _pluList = [
    {"name": "Bananas", "plu": "4011"},
    {"name": "Avocados", "plu": "4046"},
    {"name": "Tomatoes", "plu": "4063"},
    {"name": "Broccoli", "plu": "4060"},
  ];
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Produce Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _pluController,
                    decoration: const InputDecoration(labelText: 'PLU'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addOrUpdatePLU,
                  child: Text(_editingIndex == null ? 'Add' : 'Update'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _pluList.length,
                itemBuilder: (context, index) {
                  final item = _pluList[index];
                  return ListTile(
                    title: Text(item["name"] ?? ''),
                    subtitle: Text('PLU: ${item["plu"] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPLU(index),
                    ),
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
