import 'package:flutter/material.dart';
import 'dart:math';

class GeometryCalculatorsPage extends StatefulWidget {
  @override
  _GeometryCalculatorsPageState createState() => _GeometryCalculatorsPageState();
}

class _GeometryCalculatorsPageState extends State<GeometryCalculatorsPage> {
  String? _selectedCalculator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geometry Calculators'),
      ),
      body: _selectedCalculator == null
          ? _buildCalculatorList()
          : _buildSelectedCalculator(),
    );
  }

  Widget _buildCalculatorList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _CalculatorListItem(
          title: 'Circle Calculator',
          icon: Icons.circle_outlined,
          onTap: () {
            setState(() {
              _selectedCalculator = 'circle';
            });
          },
        ),
        SizedBox(height: 12),
        _CalculatorListItem(
          title: 'Rectangle Calculator',
          icon: Icons.crop_square,
          onTap: () {
            setState(() {
              _selectedCalculator = 'rectangle';
            });
          },
        ),
      ],
    );
  }

  Widget _buildSelectedCalculator() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedCalculator = null;
                  });
                },
              ),
              Text(
                _getCalculatorTitle(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _getCalculatorWidget(),
          ),
        ),
      ],
    );
  }

  String _getCalculatorTitle() {
    switch (_selectedCalculator) {
      case 'circle':
        return 'Circle Calculator';
      case 'rectangle':
        return 'Rectangle Calculator';
      default:
        return '';
    }
  }

  Widget _getCalculatorWidget() {
    switch (_selectedCalculator) {
      case 'circle':
        return CircleCalculator();
      case 'rectangle':
        return RectangleCalculator();
      default:
        return SizedBox();
    }
  }
}

class _CalculatorListItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CalculatorListItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.purple),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
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
