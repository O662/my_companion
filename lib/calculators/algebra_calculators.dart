import 'package:flutter/material.dart';
import 'dart:math';

class AlgebraCalculatorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Algebra Calculators'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            QuadraticCalculator(),
            SizedBox(height: 24),
            // Add more algebra calculators here
          ],
        ),
      ),
    );
  }
}

class QuadraticCalculator extends StatefulWidget {
  @override
  _QuadraticCalculatorState createState() => _QuadraticCalculatorState();
}

class _QuadraticCalculatorState extends State<QuadraticCalculator> {
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  String _result = '';

  void _calculate() {
    final a = double.tryParse(_aController.text) ?? 0;
    final b = double.tryParse(_bController.text) ?? 0;
    final c = double.tryParse(_cController.text) ?? 0;

    if (a == 0) {
      setState(() {
        _result = 'Error: a cannot be zero';
      });
      return;
    }

    final discriminant = b * b - 4 * a * c;

    setState(() {
      if (discriminant > 0) {
        final x1 = (-b + sqrt(discriminant)) / (2 * a);
        final x2 = (-b - sqrt(discriminant)) / (2 * a);
        _result = 'Two real roots:\nx₁ = ${x1.toStringAsFixed(2)}\nx₂ = ${x2.toStringAsFixed(2)}';
      } else if (discriminant == 0) {
        final x = -b / (2 * a);
        _result = 'One real root:\nx = ${x.toStringAsFixed(2)}';
      } else {
        final realPart = -b / (2 * a);
        final imaginaryPart = sqrt(-discriminant) / (2 * a);
        _result = 'Complex roots:\nx₁ = ${realPart.toStringAsFixed(2)} + ${imaginaryPart.toStringAsFixed(2)}i\nx₂ = ${realPart.toStringAsFixed(2)} - ${imaginaryPart.toStringAsFixed(2)}i';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quadratic Equation Solver',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'ax² + bx + c = 0',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _aController,
              decoration: InputDecoration(
                labelText: 'Coefficient a',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _bController,
              decoration: InputDecoration(
                labelText: 'Coefficient b',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _cController,
              decoration: InputDecoration(
                labelText: 'Coefficient c',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: Text('Solve'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            if (_result.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
