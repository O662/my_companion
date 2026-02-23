import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Data class ───────────────────────────────────────────────────────────────

class ProfileInfoData {
  final String nickname;
  final String firstName;
  final String lastName;
  final String email;
  final String dob;          // 'YYYY-MM-DD'
  final String gender;
  final String pronouns;
  final String height;       // cm as string
  final String weight;       // kg as string
  final bool   heightMetric;
  final bool   weightMetric;

  const ProfileInfoData({
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dob,
    required this.gender,
    required this.pronouns,
    required this.height,
    required this.weight,
    required this.heightMetric,
    required this.weightMetric,
  });
}

// ── Page ─────────────────────────────────────────────────────────────────────

class EditProfileInfoPage extends StatefulWidget {
  final ProfileInfoData initial;
  const EditProfileInfoPage({super.key, required this.initial});

  @override
  State<EditProfileInfoPage> createState() => _EditProfileInfoPageState();
}

class _EditProfileInfoPageState extends State<EditProfileInfoPage> {
  // Text controllers
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pronounsCtrl;

  // DOB
  DateTime? _dobDate;

  // Gender
  String? _genderSelected;

  // Height (stored in cm)
  late int _heightCm;
  late bool _heightMetric;

  // Weight (stored in kg)
  late double _weightKg;
  late bool _weightMetric;

  bool _saving = false;

  static const List<String> _genderOptions = [
    'Male', 'Female', 'Non-binary', 'X', 'Gender Fluid', 'Prefer not to say',
  ];


  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nicknameCtrl    = TextEditingController(text: d.nickname);
    _firstNameCtrl   = TextEditingController(text: d.firstName);
    _lastNameCtrl    = TextEditingController(text: d.lastName);
    _emailCtrl       = TextEditingController(text: d.email);
    _pronounsCtrl    = TextEditingController(text: d.pronouns);
    _dobDate         = d.dob.isNotEmpty ? DateTime.tryParse(d.dob) : null;
    _genderSelected  = _genderOptions.contains(d.gender) ? d.gender : null;
    _heightCm        = int.tryParse(d.height) ?? 0;
    _heightMetric    = d.heightMetric;
    _weightKg        = double.tryParse(d.weight) ?? 0.0;
    _weightMetric    = d.weightMetric;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _pronounsCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _dobDisplay {
    if (_dobDate == null) return 'Not set';
    final m = _dobDate!.month.toString().padLeft(2, '0');
    final d = _dobDate!.day.toString().padLeft(2, '0');
    final age = _calcAge(_dobDate!);
    return '$m/$d/${_dobDate!.year}${age != null ? ' ($age yrs)' : ''}';
  }

  int? _calcAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  String get _heightDisplay {
    if (_heightCm == 0) return 'Not set';
    if (_heightMetric) return '$_heightCm cm';
    final totalIn = (_heightCm / 2.54).round();
    final ft = totalIn ~/ 12;
    final inches = totalIn % 12;
    return '$ft\' $inches" ($_heightCm cm)';
  }

  String get _weightDisplay {
    if (_weightKg == 0.0) return 'Not set';
    final kgLabel = _weightKg == _weightKg.truncateToDouble()
        ? '${_weightKg.toInt()} kg'
        : '${_weightKg.toStringAsFixed(1)} kg';
    if (_weightMetric) return kgLabel;
    final lbs = (_weightKg * 2.20462).round();
    return '$lbs lbs ($kgLabel)';
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dobDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _dobDate = picked);
  }

  Future<void> _pickHeight() async {
    final cmValues = List.generate(151, (i) => i + 100);
    final ftValues = List.generate(5, (i) => i + 3);
    final inValues = List.generate(12, (i) => i);

    int cmIndex = (_heightCm > 0 ? (_heightCm - 100).clamp(0, 150) : 70);
    final ti0 = (_heightCm > 0 ? (_heightCm / 2.54).round() : 67);
    int ftIndex = ((ti0 ~/ 12) - 3).clamp(0, 4);
    int inIndex = (ti0 % 12).clamp(0, 11);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        bool pickerMetric = _heightMetric;
        int resultCm() {
          if (pickerMetric) return cmValues[cmIndex];
          return ((ftValues[ftIndex] * 12 + inValues[inIndex]) * 2.54).round();
        }
        return SizedBox(
          height: 340,
          child: Column(children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('cm'),
                  selected: pickerMetric,
                  onSelected: (_) => setSheet(() {
                    pickerMetric = true;
                    cmIndex = (resultCm() - 100).clamp(0, 150);
                  }),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('ft & in'),
                  selected: !pickerMetric,
                  onSelected: (_) => setSheet(() {
                    pickerMetric = false;
                    final ti = (cmValues[cmIndex] / 2.54).round();
                    ftIndex = ((ti ~/ 12) - 3).clamp(0, 4);
                    inIndex = (ti % 12).clamp(0, 11);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: pickerMetric
                  ? CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: cmIndex),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => setSheet(() => cmIndex = i),
                      children: cmValues.map((v) => Center(child: Text('$v cm'))).toList(),
                    )
                  : Row(children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: ftIndex),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) => setSheet(() => ftIndex = i),
                          children: ftValues.map((v) => Center(child: Text('$v ft'))).toList(),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: inIndex),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) => setSheet(() => inIndex = i),
                          children: inValues.map((v) => Center(child: Text('$v in'))).toList(),
                        ),
                      ),
                    ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cm = resultCm();
                    Navigator.pop(ctx);
                    setState(() {
                      _heightCm = cm;
                      _heightMetric = pickerMetric;
                    });
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _pickWeight() async {
    final kgValues = List.generate(561, (i) => 20.0 + i * 0.5);
    final lbValues = List.generate(618, (i) => i + 44);

    int kgIndex  = (_weightKg > 0 ? ((_weightKg - 20.0) / 0.5).round().clamp(0, 560) : 100);
    int lbsIndex = (_weightKg > 0 ? ((_weightKg * 2.20462).round() - 44).clamp(0, 617) : 110);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        bool pickerMetric = _weightMetric;
        double resultKg() => pickerMetric
            ? kgValues[kgIndex]
            : lbValues[lbsIndex] / 2.20462;
        return SizedBox(
          height: 320,
          child: Column(children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('kg'),
                  selected: pickerMetric,
                  onSelected: (_) => setSheet(() {
                    pickerMetric = true;
                    kgIndex = ((resultKg() - 20.0) / 0.5).round().clamp(0, 560);
                  }),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('lbs'),
                  selected: !pickerMetric,
                  onSelected: (_) => setSheet(() {
                    pickerMetric = false;
                    lbsIndex = ((kgValues[kgIndex] * 2.20462).round() - 44).clamp(0, 617);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: pickerMetric
                  ? CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: kgIndex),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => setSheet(() => kgIndex = i),
                      children: kgValues.map((v) {
                        final label = v == v.truncateToDouble()
                            ? '${v.toInt()} kg'
                            : '${v.toStringAsFixed(1)} kg';
                        return Center(child: Text(label));
                      }).toList(),
                    )
                  : CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: lbsIndex),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => setSheet(() => lbsIndex = i),
                      children: lbValues.map((v) => Center(child: Text('$v lbs'))).toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final kg = resultKg();
                    Navigator.pop(ctx);
                    setState(() {
                      _weightKg = kg;
                      _weightMetric = pickerMetric;
                    });
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final dobStr = _dobDate != null
          ? '${_dobDate!.year}-'
            '${_dobDate!.month.toString().padLeft(2, '0')}-'
            '${_dobDate!.day.toString().padLeft(2, '0')}'
          : '';
      final weightStored = _weightKg == _weightKg.truncateToDouble()
          ? _weightKg.toInt().toString()
          : _weightKg.toStringAsFixed(1);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nickname':   _nicknameCtrl.text.trim(),
        'first_name': _firstNameCtrl.text.trim(),
        'last_name':  _lastNameCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'dob':        dobStr,
        'gender':     _genderSelected ?? '',
        'pronouns':   _pronounsCtrl.text.trim(),
        'height':     _heightCm > 0 ? _heightCm.toString() : '',
        'weight':     _weightKg > 0 ? weightStored : '',
      }, SetOptions(merge: true));

      // Keep Firebase Auth display name in sync
      await user.updateDisplayName(
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim());

      if (mounted) {
        Navigator.pop(
          context,
          ProfileInfoData(
            nickname:      _nicknameCtrl.text.trim(),
            firstName:     _firstNameCtrl.text.trim(),
            lastName:      _lastNameCtrl.text.trim(),
            email:         _emailCtrl.text.trim(),
            dob:           dobStr,
            gender:        _genderSelected ?? '',
            pronouns:      _pronounsCtrl.text.trim(),
            height:        _heightCm > 0 ? _heightCm.toString() : '',
            weight:        _weightKg > 0 ? weightStored : '',
            heightMetric:  _heightMetric,
            weightMetric:  _weightMetric,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: Colors.grey,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );

  Widget _textField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _tappableRow(String label, String value, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          child: Text(value,
              style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('NAME'),
            _textField(_nicknameCtrl, 'Nickname / Preferred Name'),
            _textField(_firstNameCtrl, 'First Name'),
            _textField(_lastNameCtrl, 'Last Name'),

            _sectionLabel('CONTACT'),
            _textField(_emailCtrl, 'Email',
                keyboardType: TextInputType.emailAddress),

            _sectionLabel('PERSONAL'),
            _tappableRow('Date of Birth', _dobDisplay, Icons.cake, _pickDob),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: _genderSelected,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genderSelected = v),
              ),
            ),
            _textField(_pronounsCtrl, 'Pronouns (e.g. he/him, she/her, they/them)'),


            _sectionLabel('BODY'),
            _tappableRow('Height', _heightDisplay, Icons.height, _pickHeight),
            _tappableRow('Weight', _weightDisplay, Icons.monitor_weight_outlined, _pickWeight),

            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Profile'),
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
