import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Markdown_parser.dart';
import 'package:uuid/uuid.dart';

class MarkdownNew extends StatefulWidget {
  final String initialValue;
  final String title;

  MarkdownNew({required this.initialValue, required this.title});

  @override
  _MarkdownNewState createState() => _MarkdownNewState();
}

class _MarkdownNewState extends State<MarkdownNew> {
  late TextEditingController controller;
  late TextEditingController titlecontroller;
  String previewdata = '';
  bool showpreview = false;
  bool isDarkMode = false;
  late SharedPreferences _prefs;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    titlecontroller = TextEditingController(text: widget.title);
    _loadTheme();
  }

  @override
  void dispose() {
    controller.dispose();
    titlecontroller.dispose();
    super.dispose();
  }

  void _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    });
  }

  void savenewMarkdown() async {
    if (!mounted) {
      return;
    }

    await savefile(context);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('File saved'),
      duration: Duration(seconds: 1),
    ));
    // add a delay before navigating back to previous screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<void> savefile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    String title = titlecontroller.text.trim();
    if (title.isEmpty) return;

    final fileContent = controller.text.trim();

    if (fileContent.isEmpty) return;

    final filesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('files');

    QuerySnapshot<Map<String, dynamic>> snapshot =
        await filesRef.where('title', isEqualTo: title).get();
    if (snapshot.docs.isNotEmpty) {
      int count = 1;
      String newTitle;
      do {
        newTitle = '$title($count)';
        count++;
        snapshot = await filesRef.where('title', isEqualTo: newTitle).get();
        title = newTitle;
      } while (snapshot.docs.isNotEmpty);
      titlecontroller.text = newTitle;
    }

    final newFileId = const Uuid().v4();
    List<String> filearrays = fileContent.split(' ');
    await filesRef.doc(newFileId).set({
      'fid': newFileId,
      'title': title,
      'file_content': fileContent,
      'last_updated': DateTime.now(),
      'created_at': DateTime.now(),
      'FileArrays': filearrays,
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleController = titlecontroller;
    final contentController = controller;

    return WillPopScope(
        onWillPop: () async {
          if (titleController.text.isNotEmpty ||
              contentController.text.isNotEmpty) {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Save changes?'),
                content: const Text(
                    'All changes made will be lost. Do you want to save the changes?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('Exit without saving'),
                  ),
                  TextButton(
                    onPressed: () {
                      savenewMarkdown();
                      Navigator.pop(context, true);
                    },
                    child: const Text('Save & Exit'),
                  )
                ],
              ),
            );

            return result ?? true;
          }

          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Markdown Editor"),
            actions: [
              IconButton(
                onPressed: () async {
                  final title = titleController.text;
                  final content = contentController.text;

                  if (title.isNotEmpty && content.isNotEmpty) {
                    savenewMarkdown();
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save),
              ),
              IconButton(
                icon:
                    Icon(showpreview ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    previewdata = contentController.text;
                    showpreview = !showpreview;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(10),
                  border: Border.all(width: 1, color: Colors.grey),
                ),
                child: TextField(
                  controller: titlecontroller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "File title",
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Flexible(
                                child: SingleChildScrollView(
                                  child: TextField(
                                    controller: contentController,
                                    onChanged: (contentController) => setState(
                                        () => previewdata = contentController),
                                    decoration: const InputDecoration(
                                        hintText: "Markdown content",
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8)),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                child: Column(children: [
                                  if (showpreview) const Divider(thickness: 4),
                                  if (showpreview)
                                    Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: const Text(
                                        "Preview",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  if (showpreview) const Divider(thickness: 4),
                                  if (showpreview)
                                    Flexible(
                                      child: MarkdownParser(data: previewdata),
                                    ),
                                ]),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
