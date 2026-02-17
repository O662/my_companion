import 'package:flutter/material.dart';
import 'dart:math';

class GeometryCalculatorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geometry Calculators'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleCalculator(),
            SizedBox(height: 24),
            RectangleCalculator(),
            SizedBox(height: 24),
            // Add more geometry calculators here
          ],
        ),
      ),
    );
  }
}

class CircleCalculator extends StatefulWidget {
  @override
  _CircleCalculatorState createState() => _CircleCalculatorState();
}

class _CircleCalculatorState extends State<CircleCalculator> {
  final _radiusController = TextEditingController();
  double _area = 0.0;
  double _circumference = 0.0;

  void _calculate() {
    final radius = double.tryParse(_radiusController.text) ?? 0;
    setState(() {
      _area = pi * radius * radius;
      _circumference = 2 * pi * radius;
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
              'Circle Calculator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _radiusController,
              decoration: InputDecoration(
                labelText: 'Radius',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: Text('Calculate'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Area:', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_area.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Circumference:', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_circumference.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RectangleCalculator extends StatefulWidget {
  @override
  _RectangleCalculatorState createState() => _RectangleCalculatorState();
}

class _RectangleCalculatorState extends State<RectangleCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  double _area = 0.0;
  double _perimeter = 0.0;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    setState(() {
      _area = length * width;
      _perimeter = 2 * (length + width);
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
              'Rectangle Calculator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _lengthController,
              decoration: InputDecoration(
                labelText: 'Length',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _widthController,
              decoration: InputDecoration(
                labelText: 'Width',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: Text('Calculate'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Area:', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_area.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Perimeter:', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_perimeter.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
