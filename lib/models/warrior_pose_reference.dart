import 'dart:ui';

class WarriorPoseReference {
  static const String poseName = 'Warrior Pose (Virabhadrasana)';
  static const String imagePath = 'assets/images/warrior_pose.png';
  static const String version = 'warrior_pose_virabhadrasana_v1';

  // Normalized landmarks extracted from the provided Warrior Pose reference
  // image. Coordinates are normalized to the visible body bounds.
  static const Map<String, Offset> landmarks = {
    'nose': Offset(0.32, 0.12),
    'leftEye': Offset(0.31, 0.10),
    'rightEye': Offset(0.35, 0.10),
    'leftEar': Offset(0.39, 0.12),
    'rightEar': Offset(0.42, 0.12),
    'leftShoulder': Offset(0.38, 0.28),
    'rightShoulder': Offset(0.53, 0.28),
    'leftElbow': Offset(0.18, 0.28),
    'rightElbow': Offset(0.75, 0.28),
    'leftWrist': Offset(0.00, 0.28),
    'rightWrist': Offset(1.00, 0.28),
    'leftHip': Offset(0.40, 0.52),
    'rightHip': Offset(0.57, 0.52),
    'leftKnee': Offset(0.19, 0.68),
    'rightKnee': Offset(0.75, 0.69),
    'leftAnkle': Offset(0.07, 0.96),
    'rightAnkle': Offset(0.92, 0.96),
    'leftHeel': Offset(0.03, 0.98),
    'rightHeel': Offset(0.94, 0.98),
    'leftFootIndex': Offset(0.13, 0.96),
    'rightFootIndex': Offset(0.89, 0.96),
  };

  static const Map<String, double> jointAngles = {
    'leftElbow': 176,
    'rightElbow': 176,
    'leftKnee': 92,
    'rightKnee': 171,
    'leftHip': 104,
    'rightHip': 169,
    'spineLean': 4,
    'shoulderTilt': 0,
    'hipTilt': 0,
  };
}
