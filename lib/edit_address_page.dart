import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressData {
  final String street;
  final String city;
  final String state;
  final String country;
  final String zip;

  const AddressData({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.zip,
  });
}

class EditAddressPage extends StatefulWidget {
  final AddressData initial;
  const EditAddressPage({super.key, required this.initial});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _zipCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _streetCtrl  = TextEditingController(text: widget.initial.street);
    _cityCtrl    = TextEditingController(text: widget.initial.city);
    _stateCtrl   = TextEditingController(text: widget.initial.state);
    _countryCtrl = TextEditingController(text: widget.initial.country);
    _zipCtrl     = TextEditingController(text: widget.initial.zip);
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _zipCtrl.dispose();
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
        'address_street':  _streetCtrl.text.trim(),
        'address_city':    _cityCtrl.text.trim(),
        'address_state':   _stateCtrl.text.trim(),
        'address_country': _countryCtrl.text.trim(),
        'address_zip':     _zipCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(
          context,
          AddressData(
            street:  _streetCtrl.text.trim(),
            city:    _cityCtrl.text.trim(),
            state:   _stateCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            zip:     _zipCtrl.text.trim(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address. Please try again.')),
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
    TextInputAction textInputAction = TextInputAction.next,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: isLast ? TextInputAction.done : textInputAction,
        onFieldSubmitted: isLast ? (_) => _save() : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Home Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.home, size: 64, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                'Update your home address',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              _field(controller: _streetCtrl,  label: 'Street Address'),
              _field(controller: _cityCtrl,    label: 'City'),
              _field(controller: _stateCtrl,   label: 'State / Province'),
              _field(controller: _countryCtrl, label: 'Country'),
              _field(
                controller: _zipCtrl,
                label: 'Zip / Postal Code',
                keyboardType: TextInputType.number,
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
                  label: Text(_saving ? 'Saving…' : 'Save Address'),
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
