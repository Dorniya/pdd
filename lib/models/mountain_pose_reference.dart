import 'dart:ui';

class MountainPoseReference {
  static const String poseName = 'Mountain Pose (Tadasana)';
  static const String imagePath = 'assets/images/mountain_pose.png';
  static const String version = 'mountain_pose_tadasana_v1';

  // Normalized landmarks saved from the provided Mountain Pose reference image.
  static const Map<String, Offset> landmarks = {
    'nose': Offset(0.50, 0.03),
    'leftShoulder': Offset(0.42, 0.20),
    'rightShoulder': Offset(0.58, 0.20),
    'leftElbow': Offset(0.38, 0.38),
    'rightElbow': Offset(0.62, 0.38),
    'leftWrist': Offset(0.37, 0.54),
    'rightWrist': Offset(0.63, 0.54),
    'leftHip': Offset(0.44, 0.48),
    'rightHip': Offset(0.56, 0.48),
    'leftKnee': Offset(0.46, 0.72),
    'rightKnee': Offset(0.54, 0.72),
    'leftAnkle': Offset(0.48, 0.97),
    'rightAnkle': Offset(0.52, 0.97),
    'leftFootIndex': Offset(0.47, 1.00),
    'rightFootIndex': Offset(0.53, 1.00),
  };

  static const Map<String, double> jointAngles = {
    'leftElbow': 176,
    'rightElbow': 176,
    'leftKnee': 178,
    'rightKnee': 178,
    'leftHip': 176,
    'rightHip': 176,
    'spineLean': 0,
    'shoulderTilt': 0,
    'hipTilt': 0,
  };

  static const double armsCloseDistance = 0.075;
  static const double feetDistance = 0.055;
}
