import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'userdata.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late SharedPreferences _prefs;

  late User _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  UserData? _loggedInUser;
  bool IsDarkmode = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
    getUserData();
  }

  void getUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    _loggedInUser = await UserData.getUserDataByUid(uid);
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot documentSnapshot =
            await _db.collection('users').doc(currentUser.uid).get();
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _user = currentUser;
          _firstNameController.text = data['firstName'];
          _lastNameController.text = data['secondName'];
          _emailController.text = data['email'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _loggedInUser!.profileImageUrl != null
                          ? NetworkImage(_loggedInUser!.profileImageUrl!,
                              scale: 0.1)
                          : const AssetImage('images/default_profile.png')
                              as ImageProvider,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Select a new profile image"),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("Gallery"),
                                    onPressed: () async {
                                      final XFile? selectedImage =
                                          await ImagePicker().pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      final ref = FirebaseStorage.instance
                                          .ref()
                                          .child(
                                              'users/${_loggedInUser!.uid}/profileimage');
                                      final file = File(selectedImage!.path);
                                      await ref.putFile(file);
                                      final String profileImageUrl =
                                          await ref.getDownloadURL();
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_loggedInUser!.uid)
                                          .update({
                                        'profileImageUrl': profileImageUrl,
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("Camera"),
                                    onPressed: () async {
                                      final XFile? selectedImage =
                                          await ImagePicker().pickImage(
                                        source: ImageSource.camera,
                                      );
                                      final ref = FirebaseStorage.instance
                                          .ref()
                                          .child(
                                              'users/${_loggedInUser!.uid}/profileimage');
                                      final file = File(selectedImage!.path);
                                      await ref.putFile(file);
                                      final String profileImageUrl =
                                          await ref.getDownloadURL();
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_loggedInUser!.uid)
                                          .update({
                                        'profileImageUrl': profileImageUrl,
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Switch modes:',
                          style: GoogleFonts.lato(fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              themeProvider.toggleTheme(IsDarkmode);
                              IsDarkmode = !IsDarkmode;
                            });
                          },
                          icon: themeProvider.isDarkModeEnabled
                              ? const Icon(Icons.brightness_medium_outlined)
                              : const Icon(Icons.brightness_medium),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: updateUserData,
                      child: const Text('Update Profile'),
                    ),
                    ElevatedButton(
                      onPressed: () => logout(context),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> updateUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String uid = _user.uid;
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;
      String email = _emailController.text;
      await _db.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                _setIsLoggedIn(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _setIsLoggedIn(bool isLoggedIn) async {
    await _prefs.setBool('isLoggedIn', isLoggedIn);
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }
}
