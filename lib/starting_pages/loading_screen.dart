import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class LoadingScreen extends StatefulWidget {
  final Widget nextScreen;

  const LoadingScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'lib/assets/animations/Welcome.mov',
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(false);
      controller.setVolume(0);
      controller.play();

      // Navigate when the video ends (plus a tiny buffer)
      controller.addListener(() {
        final pos = controller.value.position;
        final dur = controller.value.duration;
        if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 100)) {
          _navigateNext();
        }
      });

      setState(() {
        _controller = controller;
        _videoReady = true;
      });
    } catch (e) {
      // Video failed to load — fall back to a short timed transition
      if (mounted) {
        setState(() => _videoError = true);
        Timer(const Duration(seconds: 2), _navigateNext);
      }
    }
  }

  void _navigateNext() {
    if (!mounted) return;
    _controller?.pause();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFF8E24AA),
            ],
          ),
        ),
        child: Center(
          child: _videoReady && _controller != null
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
              : _videoError
                  ? const Text(
                      'My Companion',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
        ),
      ),
    );
  }
}
