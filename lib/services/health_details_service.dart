import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_details_model.dart';

class HealthDetailsService {
  HealthDetailsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

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

  DocumentReference<Map<String, dynamic>> get _healthDetailsRef {
    return _db.collection('health_details').doc(_uid);
  }

  Stream<HealthDetailsModel?> healthDetailsStream() {
    return _healthDetailsRef.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return HealthDetailsModel.fromMap(data);
    });
  }

  Future<void> saveHealthDetails(HealthDetailsModel details) async {
    final savedDetails = details.copyWith(updatedAt: DateTime.now());
    final data = {...savedDetails.toFirestoreMap(), 'userId': _uid};
    final batch = _db.batch();
    batch.set(_healthDetailsRef, data, SetOptions(merge: true));
    batch.set(_userRef, {
      'age': savedDetails.age,
      'weight': savedDetails.weight,
      'height': savedDetails.height,
      'healthDetails': data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _userRef.collection('health_details').doc('profile'),
      data,
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
