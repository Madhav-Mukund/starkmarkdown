import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FilesScreen extends StatelessWidget {
  final String userId;

  FilesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(userId)
            .doc('files')
            .collection('files')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final files = snapshot.data!.docs;
            final sortedFiles = files
                .map((file) => MapEntry(file['title'] as String, file))
                .toList()
              ..sort((a, b) => compareNatural(a.key, b.key));
            return ListView.builder(
              itemCount: sortedFiles.length,
              itemBuilder: (context, index) {
                final file = sortedFiles[index].value;
                return ListTile(
                  title: Text(file['title'] as String),
                  subtitle: Text(file['file_content'] as String),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
