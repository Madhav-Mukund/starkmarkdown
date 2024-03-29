// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, duplicate_ignore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'markdown_editor.dart';
import 'MarkdownNew.dart';
import 'profile.dart';
import 'search.dart';
import 'userdata.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'handledeeplink.dart';
import 'login.dart';
import 'filedata.dart';

class HomeScreen extends StatefulWidget {
  final String? fileTitle;
  FileData file = FileData();
  FileData openfile = FileData();
  UserData userdata = UserData();

  HomeScreen({Key? key, this.fileTitle}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SharedPreferences prefs;
  bool isLoggedIn = false;
  User? user = FirebaseAuth.instance.currentUser;
  UserData loggedInUser = UserData();
  String sortBy = 'titleAscending';
  String sortby = 'title';
  bool sortboolby = false;
  List<String> sortedTitles = [];
  bool isDarkMode = false;
  bool s1 = false;
  bool s2 = false;
  bool s3 = false;
  List<bool> selected = [false, false, false];

  @override
  void initState() {
    super.initState();
    loadSharedPreferences();
    loadUserData();
    AuthChanges();
    initDynamicLinks();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      final Uri deepLink = dynamicLinkData.link;

      openFileFromDynamicLink(deepLink);
    });
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      openFileFromDynamicLink(deepLink);
    }
  }

  void openFileFromDynamicLink(Uri deepLink) async {
    String UserID = deepLink.queryParameters['uid']!;
    String fileID = deepLink.queryParameters['fid']!;

    final DocumentSnapshot fileSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(UserID)
        .collection('files')
        .doc(fileID)
        .get();

    String title = fileSnapshot['title'];

    String initialValue = fileSnapshot['filecontent'];
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MarkdownNew(initialValue: initialValue, title: title),
        ));
  }

  void AuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        await prefs.setBool('isLoggedIn', false);
        setState(() {
          isLoggedIn = false;
        });
      } else {
        await prefs.setBool('isLoggedIn', true);
        setState(() {
          isLoggedIn = true;
        });
      }
    });
  }

  void loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  void setIsLoggedIn(bool isLoggedIn) async {
    await prefs.setBool('isLoggedIn', isLoggedIn);
    if (mounted) {
      setState(() {
        isLoggedIn = isLoggedIn;
      });
    }
  }

  void loadUserData() async {
    if (user != null) {
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {});
      if (mounted) {
        setState(() {
          loggedInUser = UserData.fromSnapshot(userDataSnapshot);
        });
      }
    }
  }

  void mysortfunction(String value) {
    if (value == 'title') {
      sortby = 'title';
      s1 = !s1;
    } else if (value == 'dateModified') {
      sortby = 'last_updated';
      s2 = !s2;
    } else if (value == 'datecreated') {
      sortby = 'created_at';
      s3 = !s3;
    }
  }

  List<String> getSortedTitles(bool sortby, List<String> tosort) {
    List<String> titles = tosort;
    if (sortby) {
      titles.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
    } else {
      titles.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    return titles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 26, 35, 126),
          title: Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Color.fromARGB(255, 255, 193, 7), width: 2)),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundImage: loggedInUser.profileImageUrl != null
                          ? NetworkImage(loggedInUser.profileImageUrl!)
                          : AssetImage('images/default_profile.png')
                              as ImageProvider,
                    ),
                  )),
              SizedBox(width: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  "Hii ${!(loggedInUser.firstName == null) ? loggedInUser.firstName : 'User'}",
                  style: TextStyle(
                    color: Color.fromARGB(255, 236, 239, 241),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
              icon: Icon(
                Icons.search,
                color: Color.fromARGB(255, 255, 193, 7),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: Color.fromARGB(255, 255, 193, 7),
              ),
              onPressed: () {
                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(25.0, 50.0, 0.0, 0.0),
                  items: [
                    PopupMenuItem(
                      value: 'title',
                      child: Row(
                        children: [
                          selected[0] ? Icon(Icons.check) : SizedBox(width: 0),
                          SizedBox(width: 8),
                          Text('Title : ' + (s1 ? '(A-Z)' : '(Z-A)')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'dateModified',
                      child: Row(
                        children: [
                          selected[1] ? Icon(Icons.check) : SizedBox(width: 0),
                          SizedBox(width: 8),
                          Text('Date Modified :'),
                          SizedBox(
                            width: 10,
                          ),
                          Icon(s2 ? Icons.arrow_downward : Icons.arrow_upward),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'datecreated',
                      child: Row(
                        children: [
                          selected[2] ? Icon(Icons.check) : SizedBox(width: 0),
                          SizedBox(width: 8),
                          Text('Date Created :'),
                          SizedBox(
                            width: 17,
                          ),
                          Icon(s3 ? Icons.arrow_downward : Icons.arrow_upward),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  setState(() {
                    sortBy = value!;
                    mysortfunction(sortBy);
                    selected = [false, false, false];
                    if (sortBy == 'title') {
                      selected[0] = true;
                    } else if (sortBy == 'dateModified') {
                      selected[1] = true;
                    } else if (sortBy == 'datecreated') {
                      selected[2] = true;
                    }
                  });
                });
              },
            ),
            IconButton(
              onPressed: () => logout(context),
              icon: Icon(
                Icons.logout,
                color: Color.fromARGB(255, 255, 193, 7),
              ),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('files')
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
            if (sortby == 'title') {
              List<String> titles = snapshot.data!.docs
                  .map((DocumentSnapshot document) =>
                      (document.data() as Map<String, dynamic>)['title'])
                  .toList()
                  .cast<String>();
              sortedTitles = getSortedTitles(s1, titles);
            }
            if ((sortby == 'last_updated') && (!s2)) {
              List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
              documents.sort((a, b) =>
                  (b.data() as Map<String, dynamic>)['last_updated'].compareTo(
                      (a.data() as Map<String, dynamic>)['last_updated']));
              sortedTitles = documents
                  .map((document) =>
                      (document.data() as Map<String, dynamic>)['title'])
                  .toList()
                  .cast<String>();
            }
            if ((sortby == 'last_updated') && (s2)) {
              List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
              documents.sort((a, b) =>
                  (a.data() as Map<String, dynamic>)['last_updated'].compareTo(
                      (b.data() as Map<String, dynamic>)['last_updated']));
              sortedTitles = documents
                  .map((document) =>
                      (document.data() as Map<String, dynamic>)['title'])
                  .toList()
                  .cast<String>();
            }
            if ((sortby == 'created_at') && (!s3)) {
              List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
              documents.sort((a, b) => (b.data()
                      as Map<String, dynamic>)['created_at']
                  .compareTo((a.data() as Map<String, dynamic>)['created_at']));
              sortedTitles = documents
                  .map((document) =>
                      (document.data() as Map<String, dynamic>)['title'])
                  .toList()
                  .cast<String>();
            }
            if ((sortby == 'created_at') && (s3)) {
              List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
              documents.sort((a, b) => (a.data()
                      as Map<String, dynamic>)['created_at']
                  .compareTo((b.data() as Map<String, dynamic>)['created_at']));
              sortedTitles = documents
                  .map((document) =>
                      (document.data() as Map<String, dynamic>)['title'])
                  .toList()
                  .cast<String>();
            }

            return ListView(
              children: sortedTitles.map((String title) {
                QueryDocumentSnapshot document = snapshot.data!.docs.firstWhere(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['title'] == title,
                );

                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                return Column(children: [
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: ListTile(
                        title: Text(title),
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
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry>[
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
                              String uid =
                                  FirebaseAuth.instance.currentUser!.uid;
                              widget.file = (await FileData.getFileDataByTitle(
                                  data['title'], uid))!;
                              widget.userdata =
                                  (await UserData.getUserDataByUid(uid))!;
                              String mydeeplink =
                                  await Firebasedynamiclink.myDynamiclink(
                                      widget.file, widget.userdata);
                              await Share.share(
                                  'Check out my file: ${widget.file.title}\n\n$mydeeplink');
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
                                              .doc(user!.uid)
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
                      )),
                  SizedBox(
                    height: 10,
                  )
                ]);
              }).toList(),
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50.0, right: 35.0),
          child: FloatingActionButton(
            backgroundColor: Color.fromARGB(255, 26, 35, 126),
            foregroundColor: Color.fromARGB(255, 255, 193, 7),
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
                setIsLoggedIn(false);
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
}
