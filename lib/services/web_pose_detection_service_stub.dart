import '../models/pose_analysis.dart';

typedef WebPoseLandmarksCallback = void Function(List<PoseKeypoint> keypoints);
typedef WebPoseErrorCallback = void Function(String message);

class WebPoseDetectionService {
  String get viewType => '';

  Future<void> initialize({
    required WebPoseLandmarksCallback onLandmarks,
    required WebPoseErrorCallback onError,
  }) async {
    throw UnsupportedError('Web pose detection is only available on web.');
  }

  void setAnalyzing(bool enabled) {}

  void dispose() {}
}
