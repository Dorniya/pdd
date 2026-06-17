import 'dart:ui';

class CobraPoseReference {
  static const String poseName = 'Cobra Pose (Bhujangasana)';
  static const String imagePath = 'assets/images/cobra_pose.png';
  static const String version = 'cobra_pose_bhujangasana_v1';

  // Normalized landmarks from the uploaded Cobra Pose side-view image.
  // Coordinates match the live full-body normalization used by the detector.
  static const Map<String, Offset> landmarks = {
    'nose': Offset(0.67, 0.15),
    'leftEye': Offset(0.66, 0.13),
    'rightEye': Offset(0.69, 0.13),
    'leftEar': Offset(0.62, 0.17),
    'rightEar': Offset(0.64, 0.17),
    'leftShoulder': Offset(0.59, 0.33),
    'rightShoulder': Offset(0.62, 0.35),
    'leftElbow': Offset(0.66, 0.61),
    'rightElbow': Offset(0.69, 0.62),
    'leftWrist': Offset(0.77, 0.92),
    'rightWrist': Offset(0.81, 0.92),
    'leftHip': Offset(0.39, 0.66),
    'rightHip': Offset(0.43, 0.68),
    'leftKnee': Offset(0.20, 0.86),
    'rightKnee': Offset(0.24, 0.87),
    'leftAnkle': Offset(0.02, 0.91),
    'rightAnkle': Offset(0.07, 0.91),
    'leftHeel': Offset(0.00, 0.92),
    'rightHeel': Offset(0.05, 0.92),
    'leftFootIndex': Offset(0.10, 0.93),
    'rightFootIndex': Offset(0.13, 0.93),
  };

  static const Map<String, double> jointAngles = {
    'leftElbow': 160,
    'rightElbow': 160,
    'leftKnee': 172,
    'rightKnee': 172,
    'leftHip': 143,
    'rightHip': 143,
    'spineLean': 55,
  };
}
