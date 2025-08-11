import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String? _username;
  String? _firstName;
  String? _lastName;
  DateTime? _dateOfBirth;

  final TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Initialize animation to fully visible
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _username = data?['username'];
          _firstName = data?['firstName'];
          _lastName = data?['lastName'];
          final dobString = data?['dateOfBirth'];
          if (dobString != null) {
            _dateOfBirth = DateTime.tryParse(dobString);
            if (_dateOfBirth != null) {
              _dobController.text = "${_dateOfBirth!.toLocal()}".split(' ')[0];
            }
          }
          _isEditing = false; // Show view mode if data exists
          _animationController.reverse();
        });
      } else {
        // Initialize default values if no document exists
        setState(() {
          _username = '';
          _firstName = '';
          _lastName = '';
          _dobController.text = '';
          _isEditing = true; // Show edit mode for new profile
          _animationController.forward();
        });
      }
    } else {
      _isEditing = true; // No user, show edit mode
      _animationController.forward();
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _dobController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        await userDoc.set({
          'username': _username,
          'firstName': _firstName,
          'lastName': _lastName,
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        setState(() {
          _isEditing = false; // Switch to view mode after saving
          _animationController.reverse();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/boy.png'),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    String? initialValue,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue,
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onSaved: onSaved,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.purple),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0), // decreased height from default 56.0
        child: AppBar(
          title: const Text('Profile'),
          elevation: 4,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isEditing ? _buildEditForm() : _buildViewProfile(),
                ),
                Positioned(
                  top: -120,
                  right: -120,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.deepPurpleAccent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 20),
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
            textAlign: TextAlign.center,
          ),
          const Divider(thickness: 2, color: Colors.purple),
          _buildFormField(
            label: 'Username',
            icon: Icons.person,
            initialValue: _username,
            onSaved: (value) => _username = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          _buildFormField(
            label: 'First Name',
            icon: Icons.account_circle,
            initialValue: _firstName,
            onSaved: (value) => _firstName = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter first name';
              }
              return null;
            },
          ),
          _buildFormField(
            label: 'Last Name',
            icon: Icons.account_circle_outlined,
            initialValue: _lastName,
            onSaved: (value) => _lastName = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter last name';
              }
              return null;
            },
          ),
          _buildFormField(
            label: 'Date of Birth',
            icon: Icons.calendar_today,
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select date of birth';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfile() {
    return ListView(
      children: [
        _buildProfileAvatar(),
        const SizedBox(height: 20),
        const Text(
          'Profile Information',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
          textAlign: TextAlign.center,
        ),
        const Divider(thickness: 2, color: Colors.purple),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.purple),
            title: const Text('Username'),
            subtitle: Text(_username ?? ''),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.purple),
            title: const Text('First Name'),
            subtitle: Text(_firstName ?? ''),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: Colors.purple),
            title: const Text('Last Name'),
            subtitle: Text(_lastName ?? ''),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.purple),
            title: const Text('Date of Birth'),
            subtitle: Text(_dobController.text),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _animationController.forward();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            child: const Text('Edit'),
          ),
        ),
      ],
    );
  }
}
