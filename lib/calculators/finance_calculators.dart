import 'package:flutter/material.dart';
import 'dart:math';

class FinanceCalculatorsPage extends StatefulWidget {
  @override
  _FinanceCalculatorsPageState createState() => _FinanceCalculatorsPageState();
}

class _FinanceCalculatorsPageState extends State<FinanceCalculatorsPage> {
  String? _selectedCalculator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Calculators'),
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
          title: 'Simple Interest Calculator',
          icon: Icons.percent,
          onTap: () {
            setState(() {
              _selectedCalculator = 'simple';
            });
          },
        ),
        SizedBox(height: 12),
        _CalculatorListItem(
          title: 'Compound Interest Calculator',
          icon: Icons.trending_up,
          onTap: () {
            setState(() {
              _selectedCalculator = 'compound';
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
      case 'simple':
        return 'Simple Interest Calculator';
      case 'compound':
        return 'Compound Interest Calculator';
      default:
        return '';
    }
  }

  Widget _getCalculatorWidget() {
    switch (_selectedCalculator) {
      case 'simple':
        return SimpleInterestCalculator();
      case 'compound':
        return CompoundInterestCalculator();
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
        leading: Icon(icon, size: 32, color: Colors.green),
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

class SimpleInterestCalculator extends StatefulWidget {
  @override
  _SimpleInterestCalculatorState createState() => _SimpleInterestCalculatorState();
}

class _SimpleInterestCalculatorState extends State<SimpleInterestCalculator> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _timeController = TextEditingController();
  double _result = 0.0;

  void _calculate() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final time = double.tryParse(_timeController.text) ?? 0;
    setState(() {
      _result = (principal * rate * time) / 100;
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
              'Simple Interest',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _principalController,
              decoration: InputDecoration(
                labelText: 'Principal Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _rateController,
              decoration: InputDecoration(
                labelText: 'Interest Rate (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Time (years)',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Simple Interest:', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${_result.toStringAsFixed(2)}',
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

class CompoundInterestCalculator extends StatefulWidget {
  @override
  _CompoundInterestCalculatorState createState() => _CompoundInterestCalculatorState();
}

class _CompoundInterestCalculatorState extends State<CompoundInterestCalculator> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _timeController = TextEditingController();
  double _result = 0.0;
  double _totalAmount = 0.0;

  void _calculate() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final time = double.tryParse(_timeController.text) ?? 0;
    setState(() {
      _totalAmount = principal * pow((1 + rate / 100), time);
      _result = _totalAmount - principal;
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
              'Compound Interest',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _principalController,
              decoration: InputDecoration(
                labelText: 'Principal Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _rateController,
              decoration: InputDecoration(
                labelText: 'Interest Rate (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Time (years)',
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
                      Text('Compound Interest:', style: TextStyle(fontSize: 16)),
                      Text(
                        '\$${_result.toStringAsFixed(2)}',
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
                      Text('Total Amount:', style: TextStyle(fontSize: 16)),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
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
