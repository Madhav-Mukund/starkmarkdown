import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  String? uid;
  String? email;
  String? firstName;
  String? secondName;

  UserData({this.uid, this.email, this.firstName, this.secondName});

  // receiving data from server
  factory UserData.fromMap(map) {
    return UserData(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      secondName: map['secondName'],
    );
  }
  factory UserData.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return UserData(
      firstName: data['firstName'],
      secondName: data['secondName'],
      email: data['email'],
      uid: data['uid'],
    );
  }

  // sending data to our server
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'secondName': secondName,
    };
  }

  static Future<UserData?> getUserDataByUid(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final userData = UserData.fromSnapshot(snapshot);
        return userData;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }
}