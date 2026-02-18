import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:lottie/lottie.dart';

class ViewJsonPage extends StatefulWidget {
  @override
  _ViewJsonPageState createState() => _ViewJsonPageState();
}

class _ViewJsonPageState extends State<ViewJsonPage> {
  final List<String> jsonFiles = [
    'lib/assets/animations/Autumn break.json',
    'lib/assets/animations/Canada flag Lottie JSON animation.json',
    'lib/assets/animations/Canada rocket Lottie JSON animation.json',
    'lib/assets/animations/Canyon + Birds.json',
    'lib/assets/animations/Death Dance.json',
    'lib/assets/animations/E V E.json',
    'lib/assets/animations/Easter Bunny.json',
    'lib/assets/animations/Ghost Halloween.json',
    'lib/assets/animations/Girl Cycling in autumn.json',
    'lib/assets/animations/Halloween ghost.json',
    'lib/assets/animations/Halloween Pumpkin Black Cat.json',
    'lib/assets/animations/Japan Scene.json',
    'lib/assets/animations/Loader cat.json',
    'lib/assets/animations/Lost Coast.json',
    'lib/assets/animations/Mountain With Sun.json',
    'lib/assets/animations/October go.json',
    'lib/assets/animations/Paragliding on the Coast.json',
    'lib/assets/animations/People in autumn scene.json',
    'lib/assets/animations/Programming Computer.json',
    'lib/assets/animations/ski touring (backcountry skiing).json',
    'lib/assets/animations/sunshine.json',
    'lib/assets/animations/Tetons + Elk.json',
    'lib/assets/animations/Trick & Treat!.json',
    'lib/assets/animations/Web Robots.json',
    'lib/assets/animations/Welcome.json',
  ];

  String _getFileName(String path) {
    return path.split('/').last;
  }

  Future<void> _viewAnimation(String filePath) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: AnimationViewer(filePath: filePath, fileName: _getFileName(filePath)),
        );
      },
    ).then((_) {
      // Ensure cleanup after dialog is dismissed
      if (mounted) {
        setState(() {}); // Trigger rebuild if needed
      }
    });
  }

  Future<void> _viewJsonContent(String filePath) async {
    try {
      final String jsonContent = await rootBundle.loadString(filePath);
      final dynamic jsonData = json.decode(jsonContent);
      final String prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getFileName(filePath),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        prettyJson,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading JSON: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Animations'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lottie Animations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${jsonFiles.length} animations available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: jsonFiles.length,
                itemBuilder: (context, index) {
                  final filePath = jsonFiles[index];
                  final fileName = _getFileName(filePath);
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.animation,
                        color: Colors.amber[700],
                        size: 32,
                      ),
                      title: Text(fileName),
                      subtitle: Text(
                        'Tap to view animation',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.play_circle_outline),
                      onTap: () => _viewAnimation(filePath),
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

class AnimationViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const AnimationViewer({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  _AnimationViewerState createState() => _AnimationViewerState();
}

class _AnimationViewerState extends State<AnimationViewer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    // Stop and dispose the animation controller before disposal
    _controller.stop();
    _controller.reset();
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Stop animation when widget is being removed from tree
    _controller.stop();
    super.deactivate();
  }

  void _togglePlayPause() {
    if (!mounted) return;
    setState(() {
      if (_isPlaying) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      // Stop animation before popping
                      _controller.stop();
                      _controller.reset();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: Center(
              child: Lottie.asset(
                widget.filePath,
                controller: _controller,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  if (!mounted) return;
                  
                  // Use a post-frame callback to ensure widget is still mounted
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _controller.duration = composition.duration;
                      if (_isPlaying) {
                        _controller.repeat();
                      }
                    }
                  });
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load animation',
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Some animations require additional image assets that may not be included.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
