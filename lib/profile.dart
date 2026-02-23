import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'starting_pages/welcome_page.dart';
import 'change_password_page.dart';
import 'set_password_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String _firstName = '';
  String _lastName  = '';
  String _nickname  = '';
  String _dob       = '';  // stored as 'YYYY-MM-DD' in Firestore
  DateTime? _dobDate;
  String _email     = '';
  String _gender    = '';
  String _height    = '';
  String _weight    = '';
  bool   _heightUseMetric = true;
  bool   _weightUseMetric = true;
  DateTime? _lastPasswordChanged;
  String _addressStreet  = '';
  String _addressCity    = '';
  String _addressState   = '';
  String _addressCountry = '';
  String _addressZip     = '';
  String _language       = '';
  String? _languageSelected;
  String? _photoUrl;
  bool _loading = true;
  bool _saving  = false;
  bool _isGoogleLinked = false;
  String? _editingField;
  String? _genderSelected;

  static const List<String> _genderOptions = [
    'Male', 'Female', 'Non-binary', 'X', 'Gender Fluid', 'Prefer not to say',
  ];

  static const List<String> _languageOptions = [
    'English', 'Spanish', 'French', 'German', 'Portuguese', 'Italian',
    'Chinese (Simplified)', 'Chinese (Traditional)', 'Japanese', 'Korean',
    'Arabic', 'Hindi', 'Russian', 'Dutch', 'Polish', 'Turkish',
    'Swedish', 'Norwegian', 'Danish', 'Finnish', 'Other',
  ];

  late TabController _tabController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _addressStreetController;
  late TextEditingController _addressCityController;
  late TextEditingController _addressStateController;
  late TextEditingController _addressCountryController;
  late TextEditingController _addressZipController;

  @override
  void initState() {
    super.initState();
    _tabController              = TabController(length: 2, vsync: this);
    _firstNameController        = TextEditingController();
    _lastNameController         = TextEditingController();
    _nicknameController         = TextEditingController();
    _emailController            = TextEditingController();
    _addressStreetController    = TextEditingController();
    _addressCityController      = TextEditingController();
    _addressStateController     = TextEditingController();
    _addressCountryController   = TextEditingController();
    _addressZipController       = TextEditingController();
    _loadProfile();
    final user = FirebaseAuth.instance.currentUser;
    _isGoogleLinked = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _addressStreetController.dispose();
    _addressCityController.dispose();
    _addressStateController.dispose();
    _addressCountryController.dispose();
    _addressZipController.dispose();
    super.dispose();
  }

  int? get _calculatedAge {
    if (_dobDate == null) return null;
    final today = DateTime.now();
    int age = today.year - _dobDate!.year;
    if (today.month < _dobDate!.month ||
        (today.month == _dobDate!.month && today.day < _dobDate!.day)) {
      age--;
    }
    return age;
  }

  String _valueFor(String field) {
    switch (field) {
      case 'first_name':      return _firstName;
      case 'last_name':       return _lastName;
      case 'nickname':        return _nickname;
      case 'email':           return _email;
      case 'gender':          return _gender;
      case 'address_street':  return _addressStreet;
      case 'address_city':    return _addressCity;
      case 'address_state':   return _addressState;
      case 'address_country': return _addressCountry;
      case 'address_zip':     return _addressZip;
      case 'language':        return _language;
      default:                return '';
    }
  }

  TextEditingController _controllerFor(String field) {
    switch (field) {
      case 'first_name':      return _firstNameController;
      case 'last_name':       return _lastNameController;
      case 'nickname':        return _nicknameController;
      case 'email':           return _emailController;
      case 'address_street':  return _addressStreetController;
      case 'address_city':    return _addressCityController;
      case 'address_state':   return _addressStateController;
      case 'address_country': return _addressCountryController;
      case 'address_zip':     return _addressZipController;
      default:                return _firstNameController;
    }
  }

  String get _heightDisplay {
    final cm = int.tryParse(_height);
    if (cm == null) return '—';
    if (_heightUseMetric) return '$cm cm';
    final totalIn = (cm / 2.54).round();
    final ft = totalIn ~/ 12;
    final inches = totalIn % 12;
    return '$ft\' $inches" ($cm cm)';
  }

  String get _weightDisplay {
    final kg = double.tryParse(_weight);
    if (kg == null) return '—';
    final kgDisplay = kg == kg.truncateToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
    if (_weightUseMetric) return '$kgDisplay kg';
    final lbs = (kg * 2.20462).round();
    return '$lbs lbs ($kgDisplay kg)';
  }

  String _formatPasswordDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final sameYear = dt.year == now.year;
    return sameYear
        ? '${months[dt.month - 1]} ${dt.day}'
        : '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  bool get _isEmailPasswordUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _linkGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (kIsWeb) {
        final result = await user.linkWithPopup(GoogleAuthProvider());
        if (result.user != null) {
          setState(() => _isGoogleLinked = true);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('google_signin_enabled', true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google account linked successfully!')),
            );
          }
        }
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // user cancelled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.linkWithCredential(credential);
        setState(() => _isGoogleLinked = true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_signin_enabled', true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account linked successfully!')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'credential-already-in-use'
            ? 'This Google account is already linked to another user.'
            : e.code == 'provider-already-linked'
                ? 'A Google account is already linked.'
                : e.message ?? 'Failed to link Google account.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _unlinkGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // If no password provider, the user must create one first
    if (!_isEmailPasswordUser) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPasswordPage()),
      );
      if (result != true) return; // user cancelled
      // Reload user so _isEmailPasswordUser reflects the new provider
      await FirebaseAuth.instance.currentUser?.reload();
    }
    try {
      await FirebaseAuth.instance.currentUser!.unlink('google.com');
      setState(() => _isGoogleLinked = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_signin_enabled', false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google account unlinked.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to unlink Google.')),
        );
      }
    }
  }

  Future<void> _saveField(String field, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({field: value}, SetOptions(merge: true));
      if (field == 'first_name' || field == 'last_name') {
        final newFirst = field == 'first_name' ? value : _firstName;
        final newLast  = field == 'last_name'  ? value : _lastName;
        await user.updateDisplayName('$newFirst $newLast');
      }
      setState(() {
        switch (field) {
          case 'first_name': _firstName = value; break;
          case 'last_name':  _lastName  = value; break;
          case 'nickname':   _nickname  = value; break;
          case 'dob':
            _dob     = value;
            _dobDate = DateTime.tryParse(value);
            break;
          case 'email':  _email  = value; break;
          case 'gender': _gender = value; break;
          case 'height': _height = value; break;
          case 'weight': _weight = value; break;
          case 'address_street':  _addressStreet  = value; break;
          case 'address_city':    _addressCity    = value; break;
          case 'address_state':   _addressState   = value; break;
          case 'address_country': _addressCountry = value; break;
          case 'address_zip':     _addressZip     = value; break;
          case 'language':        _language       = value; break;
        }
        _editingField = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _buildEditRow({
    required String field,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isEditing    = _editingField == field;
    final controller   = _controllerFor(field);
    final displayValue = _valueFor(field);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blue),
              tooltip: isEditing ? 'Cancel' : 'Edit $label',
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    controller.text = displayValue;
                    _editingField = null;
                  } else {
                    _editingField = field;
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: keyboardType,
                      decoration: InputDecoration(
                        labelText: label,
                        border: const OutlineInputBorder(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          displayValue.isNotEmpty ? displayValue : '—',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            if (isEditing)
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Colors.green),
                tooltip: 'Save',
                onPressed: _saving
                    ? null
                    : () => _saveField(field, controller.text.trim()),
              ),
          ],
        ),
        const Divider(),
      ],
    );
  }
  Widget _buildLanguageRow() {
    final isEditing = _editingField == 'language';
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blue),
              tooltip: isEditing ? 'Cancel' : 'Edit Language',
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    _editingField = null;
                  } else {
                    _languageSelected = _languageOptions.contains(_language) ? _language : null;
                    _editingField = 'language';
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? DropdownButtonFormField<String>(
                      value: _languageSelected,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Language',
                        border: OutlineInputBorder(),
                      ),
                      items: _languageOptions
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (val) => setState(() => _languageSelected = val),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferred Language', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _language.isNotEmpty ? _language : '—',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            if (isEditing)
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Colors.green),
                tooltip: 'Save',
                onPressed: _saving
                    ? null
                    : () => _saveField('language', _languageSelected ?? ''),
              ),
          ],
        ),
        const Divider(),
      ],
    );
  }
  // ── Height picker ────────────────────────────────────────────────────────
  Widget _buildHeightRow() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit Height',
              onPressed: _showHeightPicker,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Height', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_heightDisplay, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _heightUseMetric = !_heightUseMetric),
              child: Text(_heightUseMetric ? 'ft & in' : 'cm'),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _showHeightPicker() async {
    final currentCm = int.tryParse(_height) ?? 170;
    final cmValues  = List.generate(151, (i) => i + 100); // 100–250 cm
    final ftValues  = List.generate(5, (i) => i + 3);     // 3–7 ft
    final inValues  = List.generate(12, (i) => i);        // 0–11 in

    int cmIndex = (currentCm - 100).clamp(0, 150);
    int totalIn = (currentCm / 2.54).round();
    int ftIndex = ((totalIn ~/ 12) - 3).clamp(0, 4);
    int inIndex = (totalIn % 12).clamp(0, 11);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool pickerMetric = _heightUseMetric;

          int resultCm() {
            if (pickerMetric) return cmValues[cmIndex];
            return ((ftValues[ftIndex] * 12 + inValues[inIndex]) * 2.54).round();
          }

          return SizedBox(
            height: 340,
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Unit toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('cm'),
                      selected: pickerMetric,
                      onSelected: (_) => setSheet(() {
                        pickerMetric = true;
                        _heightUseMetric = true;
                        // sync imperial selection → cm
                        cmIndex = (resultCm() - 100).clamp(0, 150);
                      }),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('ft & in'),
                      selected: !pickerMetric,
                      onSelected: (_) => setSheet(() {
                        pickerMetric = false;
                        _heightUseMetric = false;
                        // sync cm selection → imperial
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
                      : Row(
                          children: [
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
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveField('height', resultCm().toString());
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Weight picker ────────────────────────────────────────────────────────
  Widget _buildWeightRow() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit Weight',
              onPressed: _showWeightPicker,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weight', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_weightDisplay, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _weightUseMetric = !_weightUseMetric),
              child: Text(_weightUseMetric ? 'lbs' : 'kg'),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _showWeightPicker() async {
    final currentKg = double.tryParse(_weight) ?? 70.0;
    // 0.5 kg steps from 20 to 300 → 561 items
    final kgValues  = List.generate(561, (i) => 20.0 + i * 0.5);
    // whole lbs from 44 to 661
    final lbValues  = List.generate(618, (i) => i + 44);

    int kgIndex  = ((currentKg - 20.0) / 0.5).round().clamp(0, 560);
    int lbsIndex = ((currentKg * 2.20462).round() - 44).clamp(0, 617);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool pickerMetric = _weightUseMetric;

          double resultKg() {
            if (pickerMetric) return kgValues[kgIndex];
            return (lbValues[lbsIndex] / 2.20462);
          }

          return SizedBox(
            height: 320,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('kg'),
                      selected: pickerMetric,
                      onSelected: (_) => setSheet(() {
                        pickerMetric = true;
                        _weightUseMetric = true;
                        kgIndex = (((resultKg() - 20.0) / 0.5).round()).clamp(0, 560);
                      }),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('lbs'),
                      selected: !pickerMetric,
                      onSelected: (_) => setSheet(() {
                        pickerMetric = false;
                        _weightUseMetric = false;
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
                        Navigator.pop(ctx);
                        final kg = resultKg();
                        final stored = kg == kg.truncateToDouble()
                            ? kg.toInt().toString()
                            : kg.toStringAsFixed(1);
                        _saveField('weight', stored);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDobRow() {
    final isEditing   = _editingField == 'dob';
    final age         = _calculatedAge;
    final displayText = _dobDate != null
        ? '${_dobDate!.month.toString().padLeft(2, '0')}/${_dobDate!.day.toString().padLeft(2, '0')}/${_dobDate!.year}'  
          '${age != null ? ' ($age years old)' : ''}'
        : '—';

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blue),
              tooltip: isEditing ? 'Cancel' : 'Edit Date of Birth',
              onPressed: () {
                if (isEditing) {
                  setState(() => _editingField = null);
                } else {
                  _pickDob();
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date of Birth', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(displayText, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dobDate ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      final isoString = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _saveField('dob', isoString);
    }
  }

  Widget _buildGenderRow() {
    final isEditing = _editingField == 'gender';
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blue),
              tooltip: isEditing ? 'Cancel' : 'Edit Gender',
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    _editingField = null;
                  } else {
                    _genderSelected = _genderOptions.contains(_gender) ? _gender : null;
                    _editingField = 'gender';
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? DropdownButtonFormField<String>(
                      value: _genderSelected,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: _genderOptions
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _genderSelected = val),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _gender.isNotEmpty ? _gender : '—',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            if (isEditing)
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Colors.green),
                tooltip: 'Save',
                onPressed: _saving
                    ? null
                    : () => _saveField('gender', _genderSelected ?? ''),
              ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // refresh provider data
      final freshUser = FirebaseAuth.instance.currentUser!;
      _photoUrl = freshUser.photoURL;
      final isGoogle = freshUser.providerData.any((p) => p.providerId == 'google.com');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _firstName = data['first_name'] ?? '';
          _lastName  = data['last_name']  ?? '';
          _nickname  = data['nickname']   ?? '';
          _dob       = data['dob']        ?? '';
          _dobDate   = _dob.isNotEmpty ? DateTime.tryParse(_dob) : null;
          _email     = data['email']      ?? freshUser.email ?? '';
          _gender    = data['gender']     ?? '';
          _height    = data['height']     ?? '';
          _weight    = data['weight']     ?? '';
          _addressStreet  = data['address_street']  ?? '';
          _addressCity    = data['address_city']    ?? '';
          _addressState   = data['address_state']   ?? '';
          _addressCountry = data['address_country'] ?? '';
          _addressZip     = data['address_zip']     ?? '';
          _language       = data['language']        ?? '';
          final ts = data['password_last_changed'];
          _lastPasswordChanged = ts is Timestamp ? ts.toDate() : null;
          _isGoogleLinked = isGoogle;
          _firstNameController.text       = _firstName;
          _lastNameController.text        = _lastName;
          _nicknameController.text        = _nickname;
          _emailController.text           = _email;
          _addressStreetController.text   = _addressStreet;
          _addressCityController.text     = _addressCity;
          _addressStateController.text    = _addressState;
          _addressCountryController.text  = _addressCountry;
          _addressZipController.text      = _addressZip;
          _genderSelected   = _genderOptions.contains(_gender)     ? _gender   : null;
          _languageSelected = _languageOptions.contains(_language) ? _language : null;
          _loading = false;
        });
        return;
      } else {
        setState(() {
          _email = freshUser.email ?? '';
          _emailController.text = _email;
          _isGoogleLinked = isGoogle;
          _loading = false;
        });
        return;
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Column(
        children: [
          // Profile info card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: _photoUrl != null
                                    ? NetworkImage(_photoUrl!) as ImageProvider
                                    : const AssetImage('lib/assets/profile/profilepicture.png'),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nickname.isNotEmpty ? _nickname : (_firstName.isNotEmpty ? _firstName : 'Name'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _nickname.isNotEmpty
                                        ? '${_firstName.isNotEmpty ? _firstName : ''} ${_lastName.isNotEmpty ? _lastName : ''}'.trim()
                                        : (_lastName.isNotEmpty ? _lastName : ''),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Settings'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Profile tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildEditRow(field: 'nickname',   label: 'Nickname / Preferred Name'),
                            _buildEditRow(field: 'first_name', label: 'First Name'),
                            _buildEditRow(field: 'last_name',  label: 'Last Name'),
                            _buildEditRow(field: 'email',  label: 'Email', keyboardType: TextInputType.emailAddress),
                            _buildDobRow(),
                            _buildGenderRow(),
                            _buildLanguageRow(),
                            _buildHeightRow(),
                            _buildWeightRow(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Home Address',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildEditRow(field: 'address_street',  label: 'Street Address'),
                            _buildEditRow(field: 'address_city',    label: 'City'),
                            _buildEditRow(field: 'address_state',   label: 'State / Province'),
                            _buildEditRow(field: 'address_country', label: 'Country'),
                            _buildEditRow(field: 'address_zip',     label: 'Zip / Postal Code', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Settings tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: Colors.blue,
                              ),
                              title: const Text('Dark Mode'),
                              subtitle: Text(
                                themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                              ),
                              trailing: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleTheme();
                                },
                                activeColor: Colors.blue,
                              ),
                            ),
                            if (_isEmailPasswordUser) ...
                            [
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.lock_reset, color: Colors.blue),
                                title: const Text('Change Password'),
                                subtitle: Text(
                                  _lastPasswordChanged != null
                                      ? 'Last changed ${_formatPasswordDate(_lastPasswordChanged!)}'
                                      : 'Update your account password',
                                  style: (_lastPasswordChanged != null &&
                                          DateTime.now().difference(_lastPasswordChanged!).inDays > 90)
                                      ? const TextStyle(color: Color(0xFFB8860B))
                                      : null,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                                ).then((_) => _loadProfile()),
                              ),
                            ],
                            const Divider(),
                            ListTile(
                              leading: Image.asset(
                                'lib/assets/images/loginLogos/Google_Favicon_2025.png',
                                width: 32,
                                height: 32,
                              ),
                              title: const Text('Google Sign-In'),
                              subtitle: Text(
                                _isGoogleLinked
                                    ? 'Linked to your account'
                                    : 'Not linked',
                              ),
                              trailing: Switch(
                                value: _isGoogleLinked,
                                onChanged: (value) {
                                  if (value) {
                                    _linkGoogle();
                                  } else {
                                    _unlinkGoogle();
                                  }
                                },
                                activeColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
          // Logout button pinned at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => WelcomePage()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}