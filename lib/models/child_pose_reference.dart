import 'dart:ui';

class ChildPoseReference {
  static const String poseName = "Child's Pose (Balasana)";
  static const String imagePath = 'assets/images/child_pose.png';
  static const String version = 'child_pose_balasana_v1';

  // Normalized landmarks from the uploaded Child's Pose side-view image.
  // This reference is intentionally independent from all standing pose maps.
  static const Map<String, Offset> landmarks = {
    'nose': Offset(0.60, 0.76),
    'leftEye': Offset(0.59, 0.74),
    'rightEye': Offset(0.61, 0.74),
    'leftEar': Offset(0.56, 0.73),
    'rightEar': Offset(0.58, 0.73),
    'leftShoulder': Offset(0.52, 0.63),
    'rightShoulder': Offset(0.55, 0.64),
    'leftElbow': Offset(0.69, 0.82),
    'rightElbow': Offset(0.72, 0.83),
    'leftWrist': Offset(0.88, 0.90),
    'rightWrist': Offset(0.94, 0.90),
    'leftHip': Offset(0.28, 0.58),
    'rightHip': Offset(0.31, 0.60),
    'leftKnee': Offset(0.32, 0.84),
    'rightKnee': Offset(0.35, 0.86),
    'leftAnkle': Offset(0.10, 0.91),
    'rightAnkle': Offset(0.16, 0.92),
    'leftHeel': Offset(0.12, 0.89),
    'rightHeel': Offset(0.18, 0.90),
    'leftFootIndex': Offset(0.04, 0.94),
    'rightFootIndex': Offset(0.09, 0.94),
  };

  static const Map<String, double> jointAngles = {
    'leftElbow': 164,
    'rightElbow': 164,
    'leftKnee': 44,
    'rightKnee': 44,
    'leftHip': 34,
    'rightHip': 34,
    'spineLean': 72,
  };
}
