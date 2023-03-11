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
      print(e);
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
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _loggedInUser!.profileImageUrl != null
                        ? NetworkImage(_loggedInUser!.profileImageUrl!)
                        : AssetImage('images/default_profile.png')
                            as ImageProvider,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select a new profile image"),
                              actions: <Widget>[
                                TextButton(
                                  child: Text("CANCEL"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text("GALLERY"),
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
                                  child: Text("CAMERA"),
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
                  SizedBox(height: 20),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  Spacer(),
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
                            ? Icon(Icons.brightness_medium_outlined)
                            : Icon(Icons.brightness_medium),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: updateUserData,
                    child: Text('Update Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () => logout(context),
                    child: Text('Logout'),
                  ),
                ],
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
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Logout"),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                _setIsLoggedIn(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
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
