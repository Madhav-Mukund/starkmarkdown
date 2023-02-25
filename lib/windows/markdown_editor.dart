// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        final fileData = {
          'file_content': content,
          'last_updated': Timestamp.now(),
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
    final titleController = _titleController;
    final contentController = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Markdown Editor"),
        actions: [
          IconButton(
            onPressed: () async {
              final title = titleController.text;
              final content = contentController.text;

              if (title.isNotEmpty && content.isNotEmpty) {
                saveMarkdown();
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "File title",
              ),
              style: const TextStyle(color: Color.fromARGB(180, 45, 45, 45)),
              enabled: false),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Markdown",
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}
