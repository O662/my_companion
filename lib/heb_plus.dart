import 'package:flutter/material.dart';
import 'heb_plu_flashcards.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Full list loaded from CSV (and modified via Manage PLUs)
  List<Map<String, String>>? _allPluList;
  // Filtered view driven by the search field
  List<Map<String, String>>? _filteredPluList;
  bool _csvLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  // Categories derived from produce names (e.g., Apples, Onions)
  List<String> _categories = [
    'Apples',
    'Avocados',
    'Cabbage',
    'Grapes',
    'Greens',
    'Lettuce',
    'Mushrooms',
    'Onions',
    'Oranges',
    'Peppers',
    'Potatoes',
    'Squash',
    'Tomatoes',
    'Watermelons',
  ];
  String? _selectedCategory;
  // Controls whether the search bar is shown
  bool _showSearchBar = false;
  // No longer need to track _showManagePLUs for dialog

  // Small helpers to avoid calling `.isEmpty` on an undefined value in JS runtime
  bool _isEmpty(Iterable? it) => it == null || it.isEmpty;

  @override
  void initState() {
    super.initState();
    // Load CSV after the first frame to ensure DefaultAssetBundle is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCsv();
    });
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    _nameController.dispose();
    _pluController.dispose();
    super.dispose();
  }

  Future<void> _loadCsv() async {
    try {
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
        _allPluList = items;
        _filteredPluList = List<Map<String, String>>.from(items);
      _selectedCategory = null; // Reset category selection
        _csvLoaded = true;
      });
    } catch (e, st) {
      // If loading fails, log and show an empty list instead of a perpetual spinner.
      // ignore: avoid_print
      print('Error loading HEBplus.csv: $e\n$st');
      setState(() {
        _allPluList = <Map<String, String>>[];
        _filteredPluList = <Map<String, String>>[];
      _selectedCategory = null; // Reset category selection
        _csvLoaded = true;
      });
    }
  }

  void _computeCategories() {
  // We use fixed categories, so no dynamic computation is required.
  }
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pluController = TextEditingController();
  int? _editingIndex;

  void _addOrUpdatePLU() {
    final name = _nameController.text.trim();
    final plu = _pluController.text.trim();
    if (name.isEmpty || plu.isEmpty) return;
    setState(() {
      final list = _allPluList ?? <Map<String, String>>[];
      if (_editingIndex == null) {
        list.add({"name": name, "plu": plu});
        _allPluList = list;
      } else {
        if (_editingIndex! >= 0 && _editingIndex! < list.length) {
          list[_editingIndex!] = {"name": name, "plu": plu};
        }
        _editingIndex = null;
        _allPluList = list;
      }
      _nameController.clear();
      _pluController.clear();
      _computeCategories();
      _applyFilter();
    });
  }

  // Edit by PLU value (works when tapping items in the filtered list)
  void _editPLUByPlu(String plu) {
    final list = _allPluList ?? <Map<String, String>>[];
    final index = list.indexWhere((e) => e['plu'] == plu);
    if (index == -1) return;
    setState(() {
      _nameController.text = list[index]['name'] ?? '';
      _pluController.text = list[index]['plu'] ?? '';
      _editingIndex = index;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      final list = _allPluList ?? <Map<String, String>>[];
      // Start with search filter
      final searchFiltered = q.isEmpty
          ? list
          : list.where((e) {
              final name = (e['name'] ?? '').toLowerCase();
              final plu = (e['plu'] ?? '').toLowerCase();
              return name.contains(q) || plu.contains(q);
            }).toList();
      // Then apply category filter (if not 'All')
      if (_selectedCategory == null || _selectedCategory == 'All') {
        _filteredPluList = List<Map<String, String>>.from(searchFiltered);
      } else {
        final cat = _selectedCategory!.toLowerCase();
        if (cat == 'greens' || cat == 'grapes') {
          // Only match produce with the exact word 'greens' or 'grapes' in the name
          _filteredPluList = searchFiltered.where((e) {
            final name = (e['name'] ?? '').toLowerCase();
            // Use word boundary to match as a whole word
            return RegExp('\\b' + cat + '\\b').hasMatch(name);
          }).toList();
        } else {
          // Generate possible forms: singular, plural (s), plural (es)
          final forms = <String>{cat};
          if (cat.endsWith('es')) {
            forms.add(cat.substring(0, cat.length - 2));
          } else if (cat.endsWith('s')) {
            forms.add(cat.substring(0, cat.length - 1));
          } else {
            forms.add(cat + 's');
            forms.add(cat + 'es');
          }
          _filteredPluList = searchFiltered.where((e) {
            final name = (e['name'] ?? '').toLowerCase();
            // match: does the name contain any form of the category word?
            return forms.any((form) => name.contains(form));
          }).toList();
        }
      }
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
                child: const Text(
                  "Practice PLU's",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Practice Filtered button (only when a category is selected and there are filtered items)
            if (_selectedCategory != null && _selectedCategory != 'All' && !(_filteredPluList?.isEmpty ?? true))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final filtered = _filteredPluList ?? <Map<String, String>>[];
                      if (filtered.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HebPluFlashcardsPage(initialFlashcards: filtered),
                        ),
                      );
                    },
                      child: const Text(
                        'Practice Filtered',
                        style: TextStyle(color: Colors.black),
                      ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: Color.fromARGB(255, 237, 176, 22), // dark yellow
                    ),
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
                child: const Text(
                  'Study Difficult PLUs',
                  style: TextStyle(color: Colors.black),
                ),
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
            child: _isEmpty(items)
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
                child: const Text(
                  'View Difficult PLUs',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal menu with search and add buttons, divider, and categories
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (!_showSearchBar) ...[
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Search',
                      onPressed: () {
                        setState(() {
                          _showSearchBar = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Manage PLUs',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                const Text('Manage PLUs'),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Close',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      onPressed: () {
                                        _addOrUpdatePLU();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(_editingIndex == null ? 'Add' : 'Update'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const VerticalDivider(
                      width: 16,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ],
                  if (_showSearchBar)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 68,
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 16, height: 1.0),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    labelText: 'Search produce or PLU',
                                    labelStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.search, size: 30),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                                  ),
                                  keyboardType: TextInputType.text,
                                  onSubmitted: (_) {
                                    setState(() {
                                      _showSearchBar = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 28),
                                tooltip: 'Close search',
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilter();
                                  setState(() {
                                    _showSearchBar = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Category selector (horizontal scroll)
                    Expanded(
                      child: _isEmpty(_categories)
                          ? const SizedBox.shrink()
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final cat = _categories[idx];
                                final selected = cat == _selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategory = null;
                                        } else {
                                          _selectedCategory = cat;
                                        }
                                        _applyFilter();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Expanded(
              child: !_csvLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: (_filteredPluList ?? <Map<String, String>>[]).length,
                      itemBuilder: (context, index) {
                        final displayList = _filteredPluList ?? <Map<String, String>>[];
                        final item = displayList[index];
                        return ListTile(
                          title: Text(item["name"] ?? ''),
                          subtitle: Text('PLU: ${item["plu"] ?? ''}'),
                          onTap: () {
                            // Allow editing the tapped item
                            if ((item['plu'] ?? '').isNotEmpty) _editPLUByPlu(item['plu']!);
                          },
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
