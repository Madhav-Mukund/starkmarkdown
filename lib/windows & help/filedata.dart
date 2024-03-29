import 'package:cloud_firestore/cloud_firestore.dart';

class FileData {
  String? fid;
  String? title;
  String? file_content;

  FileData({this.fid, this.title, this.file_content});
  factory FileData.fromFirestore(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return FileData(
      fid: data['fid'],
      title: data['title'],
      file_content: data['file_content'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fid': fid,
      'title': title,
      'file_content': file_content,
    };
  }

  static CollectionReference<Map<String, dynamic>> getFileDataCollection(
      String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('files');
  }

  static Future<FileData?> getFileDataById(String fid, String uid) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await getFileDataCollection(uid).doc(fid).get();
    if (snapshot.exists) {
      return FileData.fromFirestore(snapshot);
    }
    return null;
  }

  static Future<FileData?> getFileDataByTitle(String title, String uid) async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await getFileDataCollection(uid)
            .where('title', isEqualTo: title)
            .limit(1)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return FileData.fromFirestore(snapshot.docs.first);
    }
    return null;
  }
}
