import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Stores all Firestore database logic for the app
class DatabaseManagement {
  DatabaseManagement();

  // Single Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection name for all app users
  static const String usersCollection = 'users';

  // -----------------------------
  // CREATE
  // -----------------------------
  // Creates a user document after Firebase Auth account creation
  Future<void> createUserData({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String accountType,
  }) async {
    final Map<String, dynamic> userData = <String, dynamic>{
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phoneNumber': phoneNumber.trim(),
      'accountType': accountType.trim().toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    debugPrint('Firestore CREATE started for uid: $uid');

    await _firestore.collection(usersCollection).doc(uid).set(userData);

    debugPrint('Firestore CREATE success for uid: $uid');
  }


    // CREATE
  // Creates a course document related to a specific instructor
Future<void> createCourseData({
  required String instructorId,
  required String instructorName,
  required String instructorEmail,
  required String title,
  required String description,
  required String courseTitle,
  required String courseDescription,
  required int maxStudentsAllowed,
  required String courseImagePath,
  required List<Map<String, dynamic>> milestones,
}) async {
  final DocumentReference<Map<String, dynamic>> courseReference =
      _firestore.collection('courses').doc();

  await courseReference.set(
    <String, dynamic>{
      'courseId': courseReference.id,
      'instructorId': instructorId,
      'instructorName': instructorName.trim(),
      'instructorEmail': instructorEmail.trim().toLowerCase(),
      'title': title.trim(),
      'description': description.trim(),
      'courseTitle': courseTitle.trim(),
      'courseDescription': courseDescription.trim(),
      'maxStudentsAllowed': maxStudentsAllowed,
      'courseImagePath': courseImagePath.trim(),
      'milestones': milestones,
      'registeredStudentIds': <String>[],
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );
}

  // -----------------------------
  // READ
  // -----------------------------
  // Gets one user document by uid
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData({
    required String uid,
  }) async {
    debugPrint('Firestore READ started for uid: $uid');

    final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await _firestore.collection(usersCollection).doc(uid).get();

    debugPrint(
      'Firestore READ finished for uid: $uid | exists: ${documentSnapshot.exists}',
    );

    return documentSnapshot;
  }

  // -----------------------------
  // UPDATE
  // -----------------------------
  // Updates selected fields for a user document
  Future<void> updateUserData({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final Map<String, dynamic> updatedData = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    debugPrint('Firestore UPDATE started for uid: $uid');

    await _firestore.collection(usersCollection).doc(uid).update(updatedData);

    debugPrint('Firestore UPDATE success for uid: $uid');
  }

  // -----------------------------
  // DELETE
  // -----------------------------
  // Deletes one user document by uid
  Future<void> deleteUserData({
    required String uid,
  }) async {
    debugPrint('Firestore DELETE started for uid: $uid');

    await _firestore.collection(usersCollection).doc(uid).delete();

    debugPrint('Firestore DELETE success for uid: $uid');
  }

  // -----------------------------
  // OPTIONAL HELPERS
  // -----------------------------
  // Checks whether a user document exists
  Future<bool> userDocumentExists({
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await _firestore.collection(usersCollection).doc(uid).get();

    return documentSnapshot.exists;
  }

  // Returns the user document reference
  DocumentReference<Map<String, dynamic>> userDocumentReference({
    required String uid,
  }) {
    return _firestore.collection(usersCollection).doc(uid);
  }

  //


  // Registers one student in a specific course
Future<void> registerStudentInCourse({
  required String courseId,
  required String studentId,
}) async {
  await _firestore.collection('courses').doc(courseId).update(
    <String, dynamic>{
      'registeredStudentIds': FieldValue.arrayUnion(<String>[studentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );
}

// Unregisters one student from a specific course
Future<void> unregisterStudentFromCourse({
  required String courseId,
  required String studentId,
}) async {
  await _firestore.collection('courses').doc(courseId).update(
    <String, dynamic>{
      'registeredStudentIds': FieldValue.arrayRemove(<String>[studentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );
}
}