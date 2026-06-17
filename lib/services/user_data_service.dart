import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please login first.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userRef {
    return _db.collection('users').doc(_uid);
  }

  DocumentReference<Map<String, dynamic>> get _settingsRef {
    return _userRef.collection('settings').doc('app');
  }

  CollectionReference<Map<String, dynamic>> get _workoutsRef {
    return _userRef.collection('workoutHistory');
  }

  CollectionReference<Map<String, dynamic>> get _favoritesRef {
    return _userRef.collection('favorites');
  }

  DocumentReference<Map<String, dynamic>> get _statsRef {
    return _db.collection('user_progress').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>> get _yogaSessionsRef {
    return _db.collection('yoga_sessions');
  }

  CollectionReference<Map<String, dynamic>> get _aiAssessmentsRef {
    return _db.collection('ai_assessments');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _userRef.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> settingsStream() {
    return _settingsRef.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> workoutHistoryStream() {
    return _workoutsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream() {
    return _favoritesRef.orderBy('title').snapshots();
  }

  Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    await _userRef.set({
      'name': name,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSettings(Map<String, dynamic> values) async {
    await _settingsRef.set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addFeedback({
    required int rating,
    required String message,
  }) async {
    await _userRef.collection('feedback').add({
      'rating': rating,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSupportRequest({
    required String subject,
    required String message,
  }) async {
    await _userRef.collection('supportRequests').add({
      'subject': subject,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSelectedData({
    required bool workoutHistory,
    required bool favorites,
    required bool profile,
  }) async {
    if (workoutHistory) {
      await _deleteCollection(_workoutsRef);
      await _deleteQuery(_yogaSessionsRef.where('userId', isEqualTo: _uid));
      await _deleteQuery(_aiAssessmentsRef.where('userId', isEqualTo: _uid));
      await _statsRef.set({
        'userId': _uid,
        'totalSessions': 0,
        'totalMinutes': 0,
        'streakDays': 0,
        'aiSessions': 0,
        'totalAiAccuracy': 0,
        'averageAiAccuracy': 0,
        'lastSessionDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (favorites) {
      await _deleteCollection(_favoritesRef);
    }
    if (profile) {
      await _userRef.set({
        'name': '',
        'email': _auth.currentUser?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
