import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'userdata.dart';
import 'markdown_editor.dart';

class SearchScreenData {
  bool filterByDate = false;
  DateTime? startDate;
  DateTime? endDate;
  String? msearchtext;
  String searchincontent = '';
  bool searchisincontent = false;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late User? _user;
  List<DocumentSnapshot> _searchResults = [];
  UserData _loggedInUser = UserData();
  String msearchtext = '';
  String ksearchtext = '';
  SearchScreenData _data = SearchScreenData();
  String? _selectedFilterOption;
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _keywordsController = TextEditingController();
  bool isDarkMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
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

  void _searchFiles(String msearchtext, bool f, String searchText) async {
    List<QueryDocumentSnapshot<Object?>> resultList = [];
    var collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('files');
    if (msearchtext.isNotEmpty) {
      Query query = collectionRef
          .orderBy('title')
          .startAt([msearchtext]).endAt(['$msearchtext\uf8ff']);
      QuerySnapshot querySnapshot = await query.get();
      List<QueryDocumentSnapshot<Object?>> titledoc =
          querySnapshot.docs.toList();
      resultList.addAll(titledoc);
    }

    if (f) {
      List<QueryDocumentSnapshot<Object?>> dateList = [];

      if (_data.startDate != null) {
        Query queryd = collectionRef.where('created_at',
            isGreaterThanOrEqualTo: _data.startDate);
        QuerySnapshot querySnapshotsd = await queryd.get();
        List<QueryDocumentSnapshot<Object?>> datedocsd =
            querySnapshotsd.docs.toList();
        dateList.addAll(datedocsd);
      }
      if (_data.endDate != null) {
        Query queryed = collectionRef.where('created_at',
            isLessThanOrEqualTo: _data.endDate);
        print(_data.endDate);
        QuerySnapshot querySnapshoted = await queryed.get();
        List<QueryDocumentSnapshot<Object?>> datedoced =
            querySnapshoted.docs.toList();
        dateList.addAll(datedoced);
      }
      resultList.addAll(dateList);
    }

    List<QueryDocumentSnapshot> results = resultList;

    if (searchText.isNotEmpty) {
      List<String> filearrays = searchText.split(' ');

      List<QueryDocumentSnapshot> contentResults =
          await _searchFilesContent(filearrays);

      results.addAll(contentResults.toSet().toList());
    }

    setState(() {
      _searchResults = results;
    });
  }

  Future<List<QueryDocumentSnapshot>> _searchFilesContent(
      List<String> filearrays) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('files')
        .where('FileArrays', arrayContainsAny: filearrays)
        .get();

    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search',
              ),
              onChanged: (value) {
                msearchtext = value;
              },
            ),
          ),
          Row(
            children: [
              const Text(
                'Options:',
                style: TextStyle(fontSize: 18.0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ButtonTheme(
                    alignedDropdown: true,
                    minWidth: 10.0,
                    child: DropdownButton<String>(
                      value: _selectedFilterOption,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFilterOption = value!;
                        });
                      },
                      items: <String>['Start Date', 'End Date', 'Keywords']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _searchFiles(
                          msearchtext, _data.filterByDate, ksearchtext);
                    },
                    child: const Text('Search'),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedFilterOption == 'Start Date')
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _startDateController.clear();
                            _data.startDate = null;
                            _data.filterByDate = false;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      _startDateController.text =
                          DateFormat('yyyy-MM-dd').format(selectedDate);
                      _data.startDate = selectedDate;
                      _data.filterByDate = true;
                    }
                  },
                ),
              ],
            ),
          if (_selectedFilterOption == 'End Date')
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _endDateController.clear();
                            _data.endDate = null;
                            _data.filterByDate = false;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      _endDateController.text =
                          DateFormat('yyyy-MM-dd').format(selectedDate);
                      _data.endDate = selectedDate;
                      _data.filterByDate = true;
                    }
                  },
                ),
              ],
            ),
          if (_selectedFilterOption == 'Keywords')
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _keywordsController,
                      decoration: InputDecoration(
                        labelText: 'Keywords',
                        hintText:
                            'Enter keywords separated by comma (up to 10)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _keywordsController.clear();
                          },
                        ),
                      ),
                      onChanged: (value) {
                        List<String> keywords =
                            _keywordsController.text.split(',');
                        if (keywords.length > 10) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please enter up to 10 keywords'),
                          ));

                          String newKeywords =
                              keywords.sublist(0, 10).join(',');
                          _keywordsController.value = TextEditingValue(
                            text: newKeywords,
                            selection: TextSelection.collapsed(
                                offset: newKeywords.length),
                          );
                        } else {
                          ksearchtext = _keywordsController.text;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          Expanded(
              child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> fileData =
                  _searchResults[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(fileData['title']),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return MarkdownEditor(
                          title: fileData['title'],
                          initialValue: fileData['file_content'],
                        );
                      },
                    ),
                  );
                },
              );
            },
          )),
          if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No files found.'),
            ),
        ],
      ),
    );
  }
}
