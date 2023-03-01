import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'userdata.dart';
import 'markdown_editor.dart';

class SearchScreenData {
  bool filterByDate = false;
  DateTime? startDate;
  DateTime? endDate;
  String? Searchtext;
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
  String searchtext = '';

  SearchScreenData _data = SearchScreenData();
  String? _selectedFilterOption;
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _keywordsController = TextEditingController();

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

  void _searchFiles(String searchText, bool f, bool s) async {
    if (searchText.isNotEmpty) {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('files')
          .orderBy('title')
          .startAt([searchText]).endAt(['$searchText\uf8ff']);
      QuerySnapshot querySnapshot = await query.get();
      List<QueryDocumentSnapshot<Object?>> filteredDocs =
          querySnapshot.docs.toList();
      if (f) {
        if (_data.startDate != null) {
          filteredDocs = filteredDocs.where((doc) {
            final createdAt = doc.get('created_at') as Timestamp;
            final createdAtDateTime = createdAt.toDate();
            return createdAtDateTime.isAfter(_data.startDate!);
          }).toList();
        }
        if (_data.endDate != null) {
          filteredDocs = filteredDocs.where((doc) {
            final createdAt = doc.get('created_at') as Timestamp;
            final createdAtDateTime = createdAt.toDate();
            return createdAtDateTime.isBefore(_data.endDate!);
          }).toList();
        } // convert the filtered iterable back to a list
      }

      List<QueryDocumentSnapshot> results = filteredDocs;

      if (s) {
        List<String> filearrays = searchText.split(' ');
        print('yaha bhi aaya');
        List<QueryDocumentSnapshot> contentResults =
            await _searchFilesContent(filearrays);
        for (var doc in contentResults.toList()) {
          print('ID: ${doc.id}');
          print('Title: ${doc['title']}');
          print('File content: ${doc['file_content']}');
          print('Created at: ${doc['created_at']}');
        }
        results.addAll(contentResults.toSet().toList());
        print(searchText);
      }

      setState(() {
        print('yaha aaya?');
        _searchResults = results;
        for (var doc in results) {
          print('ID: ${doc.id}');
          print('Title: ${doc['title']}');
          print('File content: ${doc['file_content']}');
          print('Created at: ${doc['created_at']}');
        }
        searchtext = searchText;
      });
    } else {
      setState(() {
        _searchResults = [];
        searchtext = searchText;
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> _searchFilesContent(
      List<String> filearrays) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('files')
        .where('FileArrays', arrayContainsAny: filearrays)
        .get();
    print('content lene aaya');
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
                _searchFiles(
                    value, _data.filterByDate, _data.searchisincontent);
              },
            ),
          ),
          Row(
            children: [
              Text(
                'Filter By:',
                style: TextStyle(fontSize: 20.0),
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
                      String? Searchquery;
                      if (searchtext != '') {
                        Searchquery = searchtext;
                        _data.searchisincontent = true;
                      } else {
                        Searchquery = _searchController.text;
                      }
                      _searchFiles(Searchquery, _data.filterByDate,
                          _data.searchisincontent);
                      print('dabaya');
                    },
                    child: Text('Search'),
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
                          icon: Icon(Icons.clear),
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
                  icon: Icon(Icons.calendar_today),
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
                          icon: Icon(Icons.clear),
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
                  icon: Icon(Icons.calendar_today),
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
                              'Enter keywords seperated by commas(Upto 10 keywords)',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _keywordsController.clear();
                              _data.searchisincontent = false;
                            },
                          ),
                        ),
                        onChanged: (value) {
                          searchtext = _keywordsController.text;
                        }),
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
