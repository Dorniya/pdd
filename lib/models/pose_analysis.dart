import 'dart:ui';

enum PoseStatus { correct, partial, incorrect }

enum BodyPart { arms, legs, back, neck, shoulders, hips, feet, balance }

class PoseKeypoint {
  final String name;
  final Offset position;
  final double likelihood;

  const PoseKeypoint({
    required this.name,
    required this.position,
    this.likelihood = 1,
  });
}

class PoseAnalysisResult {
  final String poseName;
  final int accuracy;
  final PoseStatus status;
  final String feedback;
  final List<String> correctionMessages;
  final List<BodyPart> incorrectParts;
  final List<PoseKeypoint> keypoints;
  final Map<String, double> jointAngles;
  final Map<String, int> checkScores;

  const PoseAnalysisResult({
    required this.poseName,
    required this.accuracy,
    required this.status,
    required this.feedback,
    this.correctionMessages = const [],
    required this.incorrectParts,
    required this.keypoints,
    this.jointAngles = const {},
    this.checkScores = const {},
  });

  bool get isComplete => accuracy >= 85;

  String get statusLabel {
    if (poseName.toLowerCase().contains('mountain')) {
      return isComplete
          ? 'Correct Mountain Pose ✅'
          : 'Incorrect Mountain Pose ❌';
    }

    if (poseName.toLowerCase().contains('tree')) {
      return isComplete ? 'Correct Tree Pose ✅' : 'Incorrect Tree Pose ❌';
    }

    if (poseName.toLowerCase().contains('warrior')) {
      return isComplete ? 'Correct Warrior Pose ✅' : 'Incorrect Warrior Pose ❌';
    }

    if (poseName.toLowerCase().contains('cobra')) {
      return isComplete ? 'Correct Cobra Pose ✅' : 'Incorrect Cobra Pose ❌';
    }

    if (poseName.toLowerCase().contains('child')) {
      return isComplete
          ? 'Correct Child\'s Pose ✅'
          : 'Incorrect Child\'s Pose ❌';
    }

    switch (status) {
      case PoseStatus.correct:
        return 'Correct';
      case PoseStatus.partial:
        return 'Partially Correct';
      case PoseStatus.incorrect:
        return 'Incorrect';
    }
  }

  Color get statusColor {
    switch (status) {
      case PoseStatus.correct:
        return const Color(0xFF2E7D32);
      case PoseStatus.partial:
        return const Color(0xFFF9A825);
      case PoseStatus.incorrect:
        return const Color(0xFFC62828);
    }
  }
}
