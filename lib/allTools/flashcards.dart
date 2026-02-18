import 'package:flutter/material.dart';
import 'heb_plus.dart';
import 'package:csv/csv.dart';

class FlashcardsPage extends StatelessWidget {
  const FlashcardsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Flashcards!'),
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final buttonWidth = screenWidth * 0.5;
                final buttonHeight = buttonWidth * 0.8;
                return SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HebPlusPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'lib/assets/images/HEBPLUs.png',
                        fit: BoxFit.cover,
                        width: buttonWidth,
                        height: buttonHeight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
