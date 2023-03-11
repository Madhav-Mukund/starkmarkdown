// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Markdown_parser.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialValue;
  final String title;

  MarkdownEditor({required this.initialValue, required this.title});

  @override
  _MarkdownEditorState createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  late TextEditingController _titleController;
  bool showpreview = false;
  String previewdata = "";
  String? initial;
  bool isDarkMode = false;
  late SharedPreferences _prefs;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _titleController = TextEditingController(text: widget.title);
    initial = _controller.text;
    _loadTheme();
  }

  void _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  void dispose() {
    saveMarkdown();
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void saveMarkdown() async {
    if (!mounted) return;
    final title = _titleController.text.trim();
    final content = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    final userFilesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('files');
    final existingFile = await userFilesCollection
        .where('title', isEqualTo: title)
        .limit(1)
        .get();
    if (existingFile.docs.isNotEmpty) {
      List<String> filearrays = content.split(' ');
      final fileData = {
        'file_content': content,
        'last_updated': Timestamp.now(),
        'FileArrays': filearrays,
      };
      await existingFile.docs.first.reference
          .set(fileData, SetOptions(merge: true));
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("File saved")));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (initial != _controller.text) {
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
                      saveMarkdown();
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
                onPressed: () {
                  if (_titleController.text.isNotEmpty &&
                      _controller.text.isNotEmpty) {
                    saveMarkdown();
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
                    previewdata = _controller.text;
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
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(10),
                  border: Border.all(width: 1, color: Colors.grey),
                ),
                child: TextField(
                  controller: _titleController,
                  readOnly: true,
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
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _controller,
                            onChanged: (_controller) =>
                                setState(() => previewdata = _controller),
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
                      if (showpreview)
                        const Divider(
                          thickness: 4,
                        ),
                      if (showpreview)
                        Container(
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Text(
                            "Preview",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (showpreview)
                        const Divider(
                          thickness: 4,
                        ),
                      if (showpreview)
                        Expanded(
                          child: MarkdownParser(data: previewdata),
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
