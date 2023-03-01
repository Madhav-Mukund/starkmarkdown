import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'MarkdownPreview.dart';

class MarkdownNew extends StatefulWidget {
  final String initialValue;
  final String title;

  MarkdownNew({required this.initialValue, required this.title});

  @override
  _MarkdownNewState createState() => _MarkdownNewState();
}

class _MarkdownNewState extends State<MarkdownNew> {
  late TextEditingController _controller;
  late TextEditingController _titleController;
  String previewdata = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void savenewMarkdown() async {
    if (!mounted) {
      return;
    }

    await _savenewFile(context);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('File saved'),
      duration: Duration(seconds: 1),
    ));
    // add a delay before navigating back to previous screen
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _savenewFile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final fileContent = _controller.text.trim();

    if (fileContent.isEmpty) return;

    final filesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('files');

    final newFileId = Uuid().v4();
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
    final titleController = _titleController;
    final contentController = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Text("Markdown Editor"),
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
            icon: Icon(Icons.save),
          ),
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () {
              previewdata = contentController.text;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyMarkdownScreen(markdown: previewdata),
                ),
              );
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
              controller: _titleController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "File title",
              ),
            ),
          ),
          Container(
            width: double.infinity,
            child: SingleChildScrollView(
              child: TextField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: "Markdown",
                ),
                onChanged: (value) {
                  previewdata = contentController.text;
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
