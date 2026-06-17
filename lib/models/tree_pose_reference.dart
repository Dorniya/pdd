import 'dart:ui';

class TreePoseReference {
  static const String poseName = 'Tree Pose (Vrikshasana)';
  static const String imagePath = 'assets/images/tree_pose.png';
  static const String version = 'tree_pose_vrikshasana_v1';

  // Normalized landmarks extracted from the provided Tree Pose reference image.
  // Coordinates are normalized to the visible body bounds, matching the live
  // landmark normalization used by PoseDetectionService.
  static const Map<String, Offset> landmarks = {
    'nose': Offset(0.72, 0.04),
    'leftEye': Offset(0.68, 0.02),
    'rightEye': Offset(0.76, 0.02),
    'leftEar': Offset(0.60, 0.05),
    'rightEar': Offset(0.83, 0.05),
    'leftShoulder': Offset(0.52, 0.19),
    'rightShoulder': Offset(0.93, 0.19),
    'leftElbow': Offset(0.48, 0.32),
    'rightElbow': Offset(0.88, 0.32),
    'leftWrist': Offset(0.66, 0.33),
    'rightWrist': Offset(0.75, 0.33),
    'leftHip': Offset(0.46, 0.49),
    'rightHip': Offset(0.77, 0.49),
    'leftKnee': Offset(0.00, 0.57),
    'rightKnee': Offset(0.73, 0.76),
    'leftAnkle': Offset(0.51, 0.64),
    'rightAnkle': Offset(0.68, 0.97),
    'leftHeel': Offset(0.44, 0.63),
    'rightHeel': Offset(0.63, 1.00),
    'leftFootIndex': Offset(0.54, 0.63),
    'rightFootIndex': Offset(0.77, 0.98),
  };

  static const Map<String, double> jointAngles = {
    'leftElbow': 78,
    'rightElbow': 78,
    'leftKnee': 42,
    'rightKnee': 174,
    'leftHip': 84,
    'rightHip': 174,
    'spineLean': 2,
    'shoulderTilt': 0,
    'hipTilt': 0,
  };
}
