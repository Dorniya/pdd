import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProgressStats {
  final int totalSessions;
  final int totalMinutes;
  final int streakDays;
  final int aiSessions;
  final int totalAiAccuracy;
  final String? lastSessionDate;

  const ProgressStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.streakDays,
    required this.aiSessions,
    required this.totalAiAccuracy,
    required this.lastSessionDate,
  });

  const ProgressStats.empty()
    : totalSessions = 0,
      totalMinutes = 0,
      streakDays = 0,
      aiSessions = 0,
      totalAiAccuracy = 0,
      lastSessionDate = null;

  int get averageAiAccuracy {
    if (aiSessions == 0) return 0;
    return (totalAiAccuracy / aiSessions).round();
  }

  factory ProgressStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ProgressStats.empty();
    return ProgressStats(
      totalSessions: (data['totalSessions'] as num?)?.toInt() ?? 0,
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      aiSessions: (data['aiSessions'] as num?)?.toInt() ?? 0,
      totalAiAccuracy: (data['totalAiAccuracy'] as num?)?.toInt() ?? 0,
      lastSessionDate: data['lastSessionDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'streakDays': streakDays,
      'aiSessions': aiSessions,
      'totalAiAccuracy': totalAiAccuracy,
      'averageAiAccuracy': averageAiAccuracy,
      'lastSessionDate': lastSessionDate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ProgressService {
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

  DocumentReference<Map<String, dynamic>> get _statsRef {
    return _db.collection('user_progress').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>> get _workoutsRef {
    return _userRef.collection('workoutHistory');
  }

  CollectionReference<Map<String, dynamic>> get _yogaSessionsRef {
    return _db.collection('yoga_sessions');
  }

  CollectionReference<Map<String, dynamic>> get _aiAssessmentsRef {
    return _db.collection('ai_assessments');
  }

  Stream<ProgressStats> statsStream() {
    debugPrint('[ProgressService] Listening to dashboard stats for $_uid');
    return _statsRef
        .snapshots()
        .map((snapshot) {
          final stats = ProgressStats.fromMap(snapshot.data());
          debugPrint(
            '[ProgressService] Stats loaded: sessions=${stats.totalSessions}, '
            'minutes=${stats.totalMinutes}, streak=${stats.streakDays}, '
            'aiSessions=${stats.aiSessions}, avgAi=${stats.averageAiAccuracy}',
          );
          return stats;
        })
        .handleError((error) {
          debugPrint('[ProgressService] Failed to read stats: $error');
        });
  }

  Future<void> ensureStatsFromHistory() async {
    try {
      final statsSnapshot = await _statsRef.get();
      if (statsSnapshot.exists) {
        await _resetExpiredStreakIfNeeded(
          ProgressStats.fromMap(statsSnapshot.data()),
        );
        return;
      }
      debugPrint(
        '[ProgressService] No stats doc found. Rebuilding from history.',
      );
      await rebuildStatsFromHistory();
    } catch (error) {
      debugPrint('[ProgressService] Failed to ensure stats: $error');
    }
  }

  Future<void> rebuildStatsFromHistory() async {
    final yogaSnapshot = await _yogaSessionsRef
        .where('userId', isEqualTo: _uid)
        .get();
    final aiSnapshot = await _aiAssessmentsRef
        .where('userId', isEqualTo: _uid)
        .get();
    final records = [
      ...yogaSnapshot.docs.map((doc) => doc.data()),
      ...aiSnapshot.docs.map((doc) => doc.data()),
    ].where((record) => record['isTrackedSession'] == true).toList();
    records.sort((a, b) {
      final aDate = a['sessionDateKey'] as String? ?? '';
      final bDate = b['sessionDateKey'] as String? ?? '';
      return aDate.compareTo(bDate);
    });

    var totalSessions = 0;
    var totalMinutes = 0;
    var aiSessions = 0;
    var totalAiAccuracy = 0;
    var streakDays = 0;
    String? lastSessionDate;

    for (final record in records) {
      totalSessions++;
      totalMinutes += (record['durationMinutes'] as num?)?.toInt() ?? 0;
      if (record['sessionType'] == 'ai_pose') {
        aiSessions++;
        totalAiAccuracy += (record['poseAccuracy'] as num?)?.toInt() ?? 0;
      }

      final dateKey = record['sessionDateKey'] as String?;
      if (dateKey != null) {
        streakDays = _nextStreak(
          previousDateKey: lastSessionDate,
          currentDateKey: dateKey,
          currentStreak: streakDays,
        );
        lastSessionDate = dateKey;
      }
    }

    final rebuiltStats = ProgressStats(
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      streakDays: _isStreakExpired(lastSessionDate) ? 0 : streakDays,
      aiSessions: aiSessions,
      totalAiAccuracy: totalAiAccuracy,
      lastSessionDate: lastSessionDate,
    );

    await _statsRef.set(rebuiltStats.toMap(), SetOptions(merge: true));
    debugPrint(
      '[ProgressService] Rebuilt stats from ${records.length} records.',
    );
  }

  Future<void> recordYogaSession({
    required String title,
    required int durationSeconds,
  }) async {
    final sessionId = await startYogaSession(title: title);
    await completeYogaSession(
      sessionId: sessionId,
      title: title,
      durationSeconds: durationSeconds,
    );
  }

  Future<String> startYogaSession({required String title}) async {
    final now = DateTime.now();
    final sessionRef = _yogaSessionsRef.doc();
    final workoutRef = _workoutsRef.doc(sessionRef.id);

    final startData = {
      'id': sessionRef.id,
      'userId': _uid,
      'title': title,
      'poseName': title,
      'poses': [title],
      'sessionType': 'yoga',
      'completionStatus': 'started',
      'isTrackedSession': false,
      'sessionDateKey': _dateKey(now),
      'date': _formatDate(now),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(sessionRef, startData, SetOptions(merge: true));
    batch.set(workoutRef, startData, SetOptions(merge: true));
    await batch.commit();
    return sessionRef.id;
  }

  Future<void> completeYogaSession({
    required String sessionId,
    required String title,
    required int durationSeconds,
  }) async {
    final minutes = _minutesFromSeconds(durationSeconds);
    final now = DateTime.now();
    final sessionRef = _yogaSessionsRef.doc(sessionId);
    final workoutRef = _workoutsRef.doc(sessionId);
    final startedAt = now.subtract(Duration(seconds: durationSeconds));

    await _recordSession(
      workoutRef: workoutRef,
      primaryRef: sessionRef,
      sessionType: 'yoga',
      durationMinutes: minutes,
      aiAccuracy: null,
      workoutData: {
        'id': sessionId,
        'userId': _uid,
        'title': title,
        'poseName': title,
        'date': _formatDate(now),
        'duration': '$minutes min',
        'durationSeconds': durationSeconds,
        'durationMinutes': minutes,
        'calories': '${minutes * 4} kcal',
        'description': 'Yoga session completed.',
        'poses': [title],
        'completionStatus': 'completed',
        'sessionType': 'yoga',
        'isTrackedSession': true,
        'sessionDateKey': _dateKey(now),
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> recordAiPoseSession({
    required String poseName,
    required int accuracy,
    required int durationSeconds,
    required bool completed,
    required List<String> incorrectParts,
    String? statusLabel,
    List<String> feedbackMessages = const [],
    Map<String, double> jointAngles = const {},
    Map<String, int> checkScores = const {},
  }) async {
    final minutes = _minutesFromSeconds(durationSeconds);
    final now = DateTime.now();
    final assessmentRef = _aiAssessmentsRef.doc();
    final workoutRef = _workoutsRef.doc(assessmentRef.id);
    final startedAt = now.subtract(Duration(seconds: durationSeconds));

    await _recordSession(
      workoutRef: workoutRef,
      primaryRef: assessmentRef,
      sessionType: 'ai_pose',
      durationMinutes: minutes,
      aiAccuracy: accuracy,
      workoutData: {
        'id': assessmentRef.id,
        'userId': _uid,
        'title': poseName,
        'poseName': poseName,
        'poseSelected': poseName,
        'date': _formatDate(now),
        'duration': '$minutes min',
        'durationSeconds': durationSeconds,
        'durationMinutes': minutes,
        'calories': '${minutes * 4} kcal',
        'description': completed
            ? 'AI-guided pose session completed with $accuracy% accuracy.'
            : 'AI-guided pose session ended with $accuracy% accuracy.',
        'poses': [poseName],
        'poseAccuracy': accuracy,
        'accuracyScore': accuracy,
        'correct': completed,
        'result': completed ? 'correct' : 'incorrect',
        'referencePoseVersion': _referenceVersionFor(poseName),
        'poseStatus': statusLabel,
        'feedbackMessages': feedbackMessages,
        'jointAngles': jointAngles,
        'checkScores': checkScores,
        'completionStatus': completed ? 'completed' : 'needs_practice',
        'incorrectParts': incorrectParts,
        'sessionType': 'ai_pose',
        'isTrackedSession': true,
        'sessionDateKey': _dateKey(now),
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _recordSession({
    required DocumentReference<Map<String, dynamic>> workoutRef,
    required DocumentReference<Map<String, dynamic>> primaryRef,
    required String sessionType,
    required int durationMinutes,
    required int? aiAccuracy,
    required Map<String, dynamic> workoutData,
  }) async {
    try {
      final batch = _db.batch();
      batch.set(primaryRef, workoutData, SetOptions(merge: true));
      batch.set(workoutRef, workoutData, SetOptions(merge: true));
      batch.set(_userRef, {
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      await rebuildStatsFromHistory();

      debugPrint(
        '[ProgressService] Saved $sessionType session: '
        'minutes=$durationMinutes accuracy=${aiAccuracy ?? 'n/a'}',
      );
    } catch (error) {
      debugPrint(
        '[ProgressService] Failed to save $sessionType session: $error',
      );
      rethrow;
    }
  }

  int _nextStreak({
    required String? previousDateKey,
    required String currentDateKey,
    required int currentStreak,
  }) {
    if (previousDateKey == null || previousDateKey.isEmpty) return 1;
    if (previousDateKey == currentDateKey) return currentStreak;

    final previous = DateTime.tryParse(previousDateKey);
    final current = DateTime.tryParse(currentDateKey);
    if (previous == null || current == null) return 1;

    final daysBetween = current.difference(previous).inDays;
    if (daysBetween == 1) return currentStreak + 1;
    if (daysBetween <= 0) return currentStreak;
    return 1;
  }

  Future<void> _resetExpiredStreakIfNeeded(ProgressStats stats) async {
    if (stats.streakDays == 0 || !_isStreakExpired(stats.lastSessionDate)) {
      return;
    }

    debugPrint(
      '[ProgressService] Streak expired after last session '
      '${stats.lastSessionDate}. Resetting to 0.',
    );
    await _statsRef.set({
      'streakDays': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool _isStreakExpired(String? lastSessionDate) {
    if (lastSessionDate == null || lastSessionDate.isEmpty) return false;
    final last = DateTime.tryParse(lastSessionDate);
    if (last == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return today.difference(lastDay).inDays > 1;
  }

  int _minutesFromSeconds(int seconds) {
    return (seconds / 60).ceil().clamp(1, 999);
  }

  String _dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _referenceVersionFor(String poseName) {
    final lower = poseName.toLowerCase();
    if (lower.contains('tree')) return 'tree_pose_vrikshasana_v1';
    if (lower.contains('warrior')) return 'warrior_pose_virabhadrasana_v1';
    if (lower.contains('cobra')) return 'cobra_pose_bhujangasana_v1';
    if (lower.contains('child')) return 'child_pose_balasana_v1';
    return 'mountain_pose_tadasana_v1';
  }
}
