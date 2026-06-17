import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'dart:ui';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import '../models/pose_analysis.dart';

typedef WebPoseLandmarksCallback = void Function(List<PoseKeypoint> keypoints);
typedef WebPoseErrorCallback = void Function(String message);

@JS('YogaPoseWeb.createSession')
external _YogaPoseSession _createSession(
  String viewType,
  JSFunction onLandmarks,
  JSFunction onError,
);

extension type _YogaPoseSession(JSObject _) implements JSObject {
  external web.HTMLElement get element;
  external void setAnalyzing(bool enabled);
  external void dispose();
}

class WebPoseDetectionService {
  WebPoseDetectionService()
    : viewType = 'yoga-pose-preview-${DateTime.now().microsecondsSinceEpoch}';

  final String viewType;
  _YogaPoseSession? _session;
  bool _registered = false;

  Future<void> initialize({
    required WebPoseLandmarksCallback onLandmarks,
    required WebPoseErrorCallback onError,
  }) async {
    _session?.dispose();

    final session = _createSession(
      viewType,
      ((JSString landmarksJson) {
        final decoded = jsonDecode(landmarksJson.toDart) as List<dynamic>;
        onLandmarks(_keypointsFromMediaPipe(decoded));
      }).toJS,
      ((JSString message) => onError(message.toDart)).toJS,
    );

    _session = session;
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => _session?.element ?? web.HTMLDivElement(),
      );
      _registered = true;
    }
  }

  void setAnalyzing(bool enabled) {
    _session?.setAnalyzing(enabled);
  }

  void dispose() {
    _session?.dispose();
    _session = null;
  }

  List<PoseKeypoint> _keypointsFromMediaPipe(List<dynamic> landmarks) {
    final rawPoints = <String, ({Offset position, double visibility})>{};

    void add(String name, int index) {
      if (index >= landmarks.length) {
        return;
      }

      final raw = landmarks[index] as Map<String, dynamic>;
      final x = (raw['x'] as num?)?.toDouble() ?? 0;
      final y = (raw['y'] as num?)?.toDouble() ?? 0;
      final visibility = (raw['visibility'] as num?)?.toDouble() ?? 0;
      rawPoints[name] = (
        position: Offset(x.clamp(0, 1), y.clamp(0, 1)),
        visibility: visibility,
      );
    }

    add('nose', 0);
    add('leftEye', 2);
    add('rightEye', 5);
    add('leftEar', 7);
    add('rightEar', 8);
    add('leftShoulder', 11);
    add('rightShoulder', 12);
    add('leftElbow', 13);
    add('rightElbow', 14);
    add('leftWrist', 15);
    add('rightWrist', 16);
    add('leftHip', 23);
    add('rightHip', 24);
    add('leftKnee', 25);
    add('rightKnee', 26);
    add('leftAnkle', 27);
    add('rightAnkle', 28);
    add('leftHeel', 29);
    add('rightHeel', 30);
    add('leftFootIndex', 31);
    add('rightFootIndex', 32);

    if (rawPoints.isEmpty) return const [];

    final visiblePoints = rawPoints.values
        .where((point) => point.visibility > 0)
        .map((point) => point.position)
        .toList();
    final boundsPoints = visiblePoints.isEmpty
        ? rawPoints.values.map((point) => point.position).toList()
        : visiblePoints;
    final minX = boundsPoints.map((point) => point.dx).reduce(min);
    final maxX = boundsPoints.map((point) => point.dx).reduce(max);
    final minY = boundsPoints.map((point) => point.dy).reduce(min);
    final maxY = boundsPoints.map((point) => point.dy).reduce(max);
    final width = max(maxX - minX, 1e-6);
    final height = max(maxY - minY, 1e-6);

    PoseKeypoint point(String name) {
      final raw = rawPoints[name];
      if (raw == null) {
        return PoseKeypoint(name: name, position: Offset.zero, likelihood: 0);
      }

      return PoseKeypoint(
        name: name,
        position: Offset(
          ((raw.position.dx - minX) / width).clamp(0, 1),
          ((raw.position.dy - minY) / height).clamp(0, 1),
        ),
        likelihood: raw.visibility,
      );
    }

    return [
      point('nose'),
      point('leftEye'),
      point('rightEye'),
      point('leftEar'),
      point('rightEar'),
      point('leftShoulder'),
      point('rightShoulder'),
      point('leftElbow'),
      point('rightElbow'),
      point('leftWrist'),
      point('rightWrist'),
      point('leftHip'),
      point('rightHip'),
      point('leftKnee'),
      point('rightKnee'),
      point('leftAnkle'),
      point('rightAnkle'),
      point('leftHeel'),
      point('rightHeel'),
      point('leftFootIndex'),
      point('rightFootIndex'),
    ];
  }
}
