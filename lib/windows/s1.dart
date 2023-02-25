import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'userdata.dart';
import 'markdown_editor.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late User? _user;
  late List<DocumentSnapshot> _searchResults;
  UserData _loggedInUser = UserData();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _searchResults = [];
    _loadUserData();
  }

  void _loadUserData() async {
    if (_user != null) {
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      setState(() {
        _loggedInUser = UserData.fromSnapshot(userDataSnapshot);
      });
    }
  }

  void _searchFiles(String searchText) async {
    if (searchText.isNotEmpty) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('files')
          .orderBy('title')
          .startAt([searchText]).endAt([searchText + '\uf8ff']).get();
      setState(() {
        _searchResults = querySnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Files'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
              ),
              onChanged: (value) {
                _searchFiles(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> data =
                    _searchResults[index].data() as Map<String, dynamic>;

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
                        child: Text('Share'),
                        value: 'share',
                      ),
                      PopupMenuItem(
                        child: Text('Delete'),
                        value: 'delete',
                      ),
                      PopupMenuItem(
                        child: Text('Edit'),
                        value: 'edit',
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'share') {
                        // TODO: implement share file functionality
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete File'),
                              content: Text(
                                  'Are you sure you want to delete this file?'),
                              actions: [
                                TextButton(
                                  child: Text('CANCEL'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('DELETE'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .collection('files')
                                        .doc(_searchResults[index].id)
                                        .delete();
                                    setState(() {
                                      _searchResults.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarkdownEditor(
                              initialValue: data['file_content'],
                              title: data['title'],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
