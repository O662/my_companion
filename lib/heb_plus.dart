import 'package:flutter/material.dart';
import 'heb_plu_flashcards.dart';

class HebPlusPage extends StatelessWidget {
  const HebPlusPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HEB PLU's"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to HEB PLU's!"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HebPluFlashcardsPage()),
                );
              },
              child: const Text("Go to HEB PLU Flashcards"),
            ),
          ],
        ),
      ),
    );
  }
}
