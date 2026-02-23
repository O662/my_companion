import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleData {
  final String brand;
  final String model;
  final String year;
  final String color;
  final String vin;

  const VehicleData({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
  });
}

class EditVehiclePage extends StatefulWidget {
  final VehicleData initial;
  const EditVehiclePage({super.key, required this.initial});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _vinCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.initial.brand);
    _modelCtrl = TextEditingController(text: widget.initial.model);
    _yearCtrl  = TextEditingController(text: widget.initial.year);
    _colorCtrl = TextEditingController(text: widget.initial.color);
    _vinCtrl   = TextEditingController(text: widget.initial.vin);
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'vehicle_brand': _brandCtrl.text.trim(),
        'vehicle_model': _modelCtrl.text.trim(),
        'vehicle_year':  _yearCtrl.text.trim(),
        'vehicle_color': _colorCtrl.text.trim(),
        'vehicle_vin':   _vinCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(
          context,
          VehicleData(
            brand: _brandCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            year:  _yearCtrl.text.trim(),
            color: _colorCtrl.text.trim(),
            vin:   _vinCtrl.text.trim(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save vehicle. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isLast = false,
    String? hint,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        maxLength: maxLength,
        onFieldSubmitted: isLast ? (_) => _save() : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          counterText: maxLength != null ? null : '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_car, size: 64, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                'Update your vehicle details',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              _field(controller: _brandCtrl, label: 'Car Brand',  hint: 'e.g. Toyota'),
              _field(controller: _modelCtrl, label: 'Model',       hint: 'e.g. Camry'),
              _field(
                controller: _yearCtrl,
                label: 'Year',
                hint: 'e.g. 2022',
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              _field(controller: _colorCtrl, label: 'Color',       hint: 'e.g. Silver'),
              _field(
                controller: _vinCtrl,
                label: 'VIN Number',
                hint: 'e.g. 1HGBH41JXMN109186',
                keyboardType: TextInputType.visiblePassword,
                maxLength: 17,
                isLast: true,
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save Vehicle'),
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
