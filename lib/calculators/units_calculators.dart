import 'package:flutter/material.dart';

class UnitsCalculatorsPage extends StatefulWidget {
  @override
  _UnitsCalculatorsPageState createState() => _UnitsCalculatorsPageState();
}

class _UnitsCalculatorsPageState extends State<UnitsCalculatorsPage> {
  String? _selectedCalculator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unit Converters'),
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
          title: 'Temperature Converter',
          icon: Icons.thermostat,
          onTap: () {
            setState(() {
              _selectedCalculator = 'temperature';
            });
          },
        ),
        SizedBox(height: 12),
        _CalculatorListItem(
          title: 'Length Converter',
          icon: Icons.straighten,
          onTap: () {
            setState(() {
              _selectedCalculator = 'length';
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
      case 'temperature':
        return 'Temperature Converter';
      case 'length':
        return 'Length Converter';
      default:
        return '';
    }
  }

  Widget _getCalculatorWidget() {
    switch (_selectedCalculator) {
      case 'temperature':
        return TemperatureConverter();
      case 'length':
        return LengthConverter();
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
        leading: Icon(icon, size: 32, color: Colors.orange),
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

class TemperatureConverter extends StatefulWidget {
  @override
  _TemperatureConverterState createState() => _TemperatureConverterState();
}

class _TemperatureConverterState extends State<TemperatureConverter> {
  final _inputController = TextEditingController();
  String _fromUnit = 'Celsius';
  String _toUnit = 'Fahrenheit';
  double _result = 0.0;

  final List<String> _units = ['Celsius', 'Fahrenheit', 'Kelvin'];

  void _convert() {
    final input = double.tryParse(_inputController.text) ?? 0;
    double celsius;

    // Convert to Celsius first
    if (_fromUnit == 'Celsius') {
      celsius = input;
    } else if (_fromUnit == 'Fahrenheit') {
      celsius = (input - 32) * 5 / 9;
    } else {
      celsius = input - 273.15;
    }

    // Convert from Celsius to target unit
    setState(() {
      if (_toUnit == 'Celsius') {
        _result = celsius;
      } else if (_toUnit == 'Fahrenheit') {
        _result = celsius * 9 / 5 + 32;
      } else {
        _result = celsius + 273.15;
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
              'Temperature Converter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromUnit,
                    decoration: InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromUnit = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toUnit,
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _toUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _convert,
              child: Text('Convert'),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Result:', style: TextStyle(fontSize: 16)),
                  Text(
                    '${_result.toStringAsFixed(2)} $_toUnit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
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

class LengthConverter extends StatefulWidget {
  @override
  _LengthConverterState createState() => _LengthConverterState();
}

class _LengthConverterState extends State<LengthConverter> {
  final _inputController = TextEditingController();
  String _fromUnit = 'Meters';
  String _toUnit = 'Feet';
  double _result = 0.0;

  final List<String> _units = ['Meters', 'Feet', 'Kilometers', 'Miles', 'Inches', 'Centimeters'];
  final Map<String, double> _toMeters = {
    'Meters': 1.0,
    'Feet': 0.3048,
    'Kilometers': 1000.0,
    'Miles': 1609.34,
    'Inches': 0.0254,
    'Centimeters': 0.01,
  };

  void _convert() {
    final input = double.tryParse(_inputController.text) ?? 0;
    final meters = input * _toMeters[_fromUnit]!;
    setState(() {
      _result = meters / _toMeters[_toUnit]!;
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
              'Length Converter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromUnit,
                    decoration: InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromUnit = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toUnit,
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _toUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _convert,
              child: Text('Convert'),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Result:', style: TextStyle(fontSize: 16)),
                  Text(
                    '${_result.toStringAsFixed(4)} $_toUnit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
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
