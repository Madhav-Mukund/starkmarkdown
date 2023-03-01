// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MarkdownPreview.dart';

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

  void saveMarkdown() {
    _saveFile(context);
  }

  void _saveFile(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _controller.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
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
      } else {
        final newFile = userFilesCollection.doc(title);
        final fileData = {
          'title': title,
          'file_content': content,
          'last_updated': Timestamp.now(),
        };
        await newFile.set(fileData);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("File saved")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title and content can't be empty")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Markdown Editor"),
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
            icon: Icon(showpreview ? Icons.visibility : Icons.visibility_off),
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
            margin: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadiusDirectional.circular(10),
              border: Border.all(width: 1, color: Colors.grey),
            ),
            child: TextField(
              style: TextStyle(color: Color.fromARGB(180, 45, 45, 45)),
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
                    Expanded(
                      child: Markdown(data: previewdata),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
