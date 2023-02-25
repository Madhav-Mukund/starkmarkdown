// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, duplicate_ignore

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starkmarkdown/windows/markdown_editor.dart';
import 'package:starkmarkdown/windows/me1.dart';
import 'package:starkmarkdown/windows/search.dart';
import 'package:starkmarkdown/windows/userdata.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'h1.dart';
import 'login.dart';
import 'filedata.dart';

class HomeScreen extends StatefulWidget {
  final String? fileTitle;
  FileData file = FileData();
  FileData openfile = FileData();

  HomeScreen({Key? key, this.fileTitle}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SharedPreferences _prefs;
  late String _markdown;
  bool _isLoggedIn = false;
  User? _user = FirebaseAuth.instance.currentUser;
  UserData _loggedInUser = UserData();
  String _sortBy = 'titleAscending';
  String sortby = 'title';
  bool sortboolby = false;

  @override
  void initState() {
    super.initState();
    _loadSharedPreferences();
    _loadUserData();
    _markdown = '';
    _subscribeToAuthChanges();
    initDynamicLinks();
  }

  void initDynamicLinks() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      print('Dynamic Link: $deepLink');
      // Navigate to the appropriate page/view using the data in the dynamic link
      // For example, if the link contains a file ID, navigate to that file's editor page
      // You can use the Navigator class to navigate to different views/pages in your app
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String FileID = deepLink.queryParameters['fid']!;
      widget.openfile = (await FileData.getFileDataById(FileID, uid))!;
      String thistitle, thisfile_content;
      thistitle = widget.openfile.title!;
      thisfile_content = widget.openfile.file_content!;
      print(thisfile_content);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownEditor(
            title: thistitle,
            initialValue: thisfile_content,
          ),
        ),
      );
    }
  }

  void _subscribeToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        // User is signed out, remove persistent authentication
        await _prefs.setBool('isLoggedIn', false);
        setState(() {
          _isLoggedIn = false;
        });
      } else {
        // User is signed in, enable persistent authentication
        await _prefs.setBool('isLoggedIn', true);
        setState(() {
          _isLoggedIn = true;
        });
      }
    });
  }

  void _loadSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    });
  }

  void _setIsLoggedIn(bool isLoggedIn) async {
    await _prefs.setBool('isLoggedIn', isLoggedIn);
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  void _loadUserData() async {
    if (_user != null) {
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (mounted) {
        setState(() {
          _loggedInUser = UserData.fromSnapshot(userDataSnapshot);
        });
      }
    }
  }

  void _mysortfunction(String value) {
    if (value == 'titleAscending') {
      sortby = 'title';
      sortboolby = false;
    } else if (value == 'titleDescending') {
      sortby = 'title';
      sortboolby = true;
    } else if (value == 'dateModifiedAscending') {
      sortby = 'last_updated';
      sortboolby = true;
    } else if (value == 'dateModifiedDescending') {
      sortby = 'last_updated';
      sortboolby = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Welcome ${_loggedInUser.firstName}"),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(),
                  ),
                );
              },
              icon: Icon(Icons.search),
            ),
            PopupMenuButton(
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                  _mysortfunction(_sortBy);
                });
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'titleAscending',
                  child: Text('Sort by title (A-Z)'),
                ),
                PopupMenuItem(
                  value: 'titleDescending',
                  child: Text('Sort by title (Z-A)'),
                ),
                PopupMenuItem(
                  value: 'dateModifiedAscending',
                  child: Text('Sort by date modified (oldest first)'),
                ),
                PopupMenuItem(
                  value: 'dateModifiedDescending',
                  child: Text('Sort by date modified (newest first)'),
                ),
              ],
              child: IconButton(
                icon: Icon(Icons.sort),
                onPressed: () {
                  // This function is called when the IconButton is pressed
                  // and shows the popup menu
                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(25.0, 50.0, 0.0, 0.0),
                    items: [
                      PopupMenuItem(
                        value: 'titleAscending',
                        child: Text('Sort by title (A-Z)'),
                      ),
                      PopupMenuItem(
                        value: 'titleDescending',
                        child: Text('Sort by title (Z-A)'),
                      ),
                      PopupMenuItem(
                        value: 'dateModifiedAscending',
                        child: Text('Sort by date modified (oldest first)'),
                      ),
                      PopupMenuItem(
                        value: 'dateModifiedDescending',
                        child: Text('Sort by date modified (newest first)'),
                      ),
                    ],
                  ).then((value) {
                    // This function is called when a popup menu item is selected
                    setState(() {
                      _sortBy = value!;
                      _mysortfunction(_sortBy);
                    });
                  });
                },
              ),
            ),
            IconButton(
              onPressed: () => logout(context),
              icon: Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .collection('files')
              .orderBy(sortby, descending: sortboolby)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No files"));
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['title']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkdownEditor(
                          initialValue: data['file_content'],
                          title: data['title'],
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        value: 'share',
                        child: Text('Share'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'share') {
                        String uid = FirebaseAuth.instance.currentUser!.uid;
                        widget.file = (await FileData.getFileDataByTitle(
                            data['title'], uid))!;
                        // TODO: implement share file functionality
                        String mydeeplink =
                            await Firebasedynamiclink.myDynamiclink(
                                widget.file);

                        print(mydeeplink);
                        print(widget.file.fid);
                        print(widget.file.file_content);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Delete file"),
                              content: Text(
                                  "Are you sure you want to delete this file? This action is permanent."),
                              actions: [
                                TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: Text("Delete"),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .collection('files')
                                        .doc(document.id)
                                        .delete();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50.0, right: 35.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarkdownNew(
                    title: widget.fileTitle ?? 'New_File',
                    initialValue: '',
                  ),
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        ));
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
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }
}
