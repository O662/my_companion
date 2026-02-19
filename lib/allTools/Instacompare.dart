import 'package:flutter/material.dart';
import 'pick_json_stub.dart' if (dart.library.html) 'pick_json_web.dart';
import 'launch_url_stub.dart' if (dart.library.html) 'launch_url_web.dart';
import '../home.dart';
import '../tools.dart';
import '../health.dart';
import '../personal.dart';
import '../bottom_nav_bar.dart';

class InstacomparePage extends StatefulWidget {
  @override
  _InstacomparePageState createState() => _InstacomparePageState();
}

class _InstacomparePageState extends State<InstacomparePage> {
  int _selectedIndex = 1;

  String? _followersFileName;
  String? _followingFileName;
  dynamic _followersJson;
  dynamic _followingJson;

  // Results
  List<_InstaEntry>? _onlyInFollowers; // follow you but you don't follow back
  List<_InstaEntry>? _onlyInFollowing; // you follow but they don't follow back
  bool _isComparing = false;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ToolsPage()),
      );
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HealthPage()),
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

  /// Extract a list of {title, href} entries from an Instagram JSON export.
  /// Handles both formats:
  ///   - Top-level array: [ { "title": ..., "string_list_data": [...] }, ... ]
  ///   - Top-level object with list values: { "key": [ ... ] }
  List<_InstaEntry> _extractEntries(dynamic jsonData) {
    final entries = <_InstaEntry>[];

    List<dynamic> itemsList = [];

    if (jsonData is List) {
      // Top-level array (e.g. following.json)
      itemsList = jsonData;
    } else if (jsonData is Map<String, dynamic>) {
      // Top-level object — collect all list values
      for (final value in jsonData.values) {
        if (value is List) {
          itemsList.addAll(value);
        }
      }
    }

    for (final item in itemsList) {
      if (item is Map<String, dynamic>) {
        String title = item['title']?.toString() ?? '';
        String href = '';

        // Extract from string_list_data[0]
        if (item['string_list_data'] is List) {
          final listData = item['string_list_data'] as List;
          if (listData.isNotEmpty && listData[0] is Map) {
            href = listData[0]['href']?.toString() ?? '';
            // If title is empty, fall back to "value" field (followers format)
            if (title.isEmpty) {
              title = listData[0]['value']?.toString() ?? '';
            }
          }
        }

        if (title.isNotEmpty && !title.contains('__deleted__')) {
          entries.add(_InstaEntry(title: title, href: href));
        }
      }
    }
    return entries;
  }

  Future<void> _pickJsonFile(int fileNumber) async {
    try {
      final result = await pickJsonFromDevice();

      if (result != null) {
        setState(() {
          if (fileNumber == 1) {
            _followersFileName = result['name'] as String;
            _followersJson = result['content'];
          } else {
            _followingFileName = result['name'] as String;
            _followingJson = result['content'];
          }
          // Clear previous results
          _onlyInFollowers = null;
          _onlyInFollowing = null;
        });
      }
    } catch (e) {
      _showError('Error reading file: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  void _compareFiles() {
    if (_followersJson == null || _followingJson == null) {
      _showError('Please upload both JSON files first.');
      return;
    }

    setState(() => _isComparing = true);

    final followers = _extractEntries(_followersJson);
    final following = _extractEntries(_followingJson);

    if (followers.isEmpty && following.isEmpty) {
      _showError('Could not find any entries with "title" in either file.');
      setState(() => _isComparing = false);
      return;
    }

    final followerTitles = followers.map((e) => e.title.toLowerCase()).toSet();
    final followingTitles = following.map((e) => e.title.toLowerCase()).toSet();

    // In followers but NOT in following = they follow you, you don't follow back
    final onlyFollowers = followers
        .where((e) => !followingTitles.contains(e.title.toLowerCase()))
        .toList();

    // In following but NOT in followers = you follow them, they don't follow back
    final onlyFollowing = following
        .where((e) => !followerTitles.contains(e.title.toLowerCase()))
        .toList();

    onlyFollowers.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    onlyFollowing.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    setState(() {
      _onlyInFollowers = onlyFollowers;
      _onlyInFollowing = onlyFollowing;
      _isComparing = false;
    });
  }

  void _clearAll() {
    setState(() {
      _followersFileName = null;
      _followingFileName = null;
      _followersJson = null;
      _followingJson = null;
      _onlyInFollowers = null;
      _onlyInFollowing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Insta Compare'),
        actions: [
          if (_followersJson != null || _followingJson != null)
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Upload buttons row
            Row(
              children: [
                Expanded(
                  child: _UploadCard(
                    label: 'Followers',
                    fileName: _followersFileName,
                    entryCount: _followersJson != null
                        ? _extractEntries(_followersJson).length
                        : null,
                    onTap: () => _pickJsonFile(1),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadCard(
                    label: 'Following',
                    fileName: _followingFileName,
                    entryCount: _followingJson != null
                        ? _extractEntries(_followingJson).length
                        : null,
                    onTap: () => _pickJsonFile(2),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Compare button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_followersJson != null && _followingJson != null && !_isComparing)
                        ? _compareFiles
                        : null,
                icon: _isComparing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.compare_arrows),
                label: Text(
                  _isComparing ? 'Comparing...' : 'Compare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(child: _buildResults(theme)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_onlyInFollowers == null || _onlyInFollowing == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Upload your Followers & Following\nJSON files and compare them',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_onlyInFollowers!.isEmpty && _onlyInFollowing!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              'Perfect match!\nEveryone you follow follows you back.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: "Don't follow\nyou back",
                  count: _onlyInFollowing!.length,
                  color: Colors.red,
                ),
                _StatChip(
                  label: "You don't\nfollow back",
                  count: _onlyInFollowers!.length,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: [
              Tab(text: "Don't follow you back (${_onlyInFollowing!.length})"),
              Tab(text: "You don't follow back (${_onlyInFollowers!.length})"),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildEntryList(
                  _onlyInFollowing!,
                  Colors.red,
                  'You follow them but they don\'t follow you',
                ),
                _buildEntryList(
                  _onlyInFollowers!,
                  Colors.blue,
                  'They follow you but you don\'t follow them',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(List<_InstaEntry> entries, Color color, String subtitle) {
    if (entries.isEmpty) {
      return Center(
        child: Text('None!', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: color.withOpacity(0.3), width: 1),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      entry.title[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: entry.href.isNotEmpty
                      ? Text(
                          entry.href,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: entry.href.isNotEmpty
                      ? Icon(Icons.open_in_new, size: 18, color: Colors.grey)
                      : null,
                  onTap: entry.href.isNotEmpty
                      ? () => launchUrlExternal(entry.href)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -- Helper widgets and models --

class _InstaEntry {
  final String title;
  final String href;

  _InstaEntry({required this.title, required this.href});
}

class _UploadCard extends StatelessWidget {
  final String label;
  final String? fileName;
  final int? entryCount;
  final VoidCallback onTap;
  final Color color;

  const _UploadCard({
    required this.label,
    required this.fileName,
    required this.entryCount,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLoaded = fileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLoaded ? color : Colors.grey.shade400,
            width: isLoaded ? 2 : 1,
          ),
          color: isLoaded ? color.withOpacity(0.08) : null,
        ),
        child: Column(
          children: [
            Icon(
              isLoaded ? Icons.description : Icons.upload_file,
              size: 36,
              color: isLoaded ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              isLoaded ? fileName! : 'Tap to upload JSON',
              style: TextStyle(
                fontSize: 12,
                color: isLoaded ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isLoaded && entryCount != null) ...[
              const SizedBox(height: 4),
              Text(
                '$entryCount entries',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
