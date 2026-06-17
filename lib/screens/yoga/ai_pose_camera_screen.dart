import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../models/pose_analysis.dart';
import '../../services/pose_detection_service.dart';
import '../../services/progress_service.dart';
import '../../services/web_pose_detection_service.dart';

class AiPoseCameraScreen extends StatefulWidget {
  final String poseName;

  const AiPoseCameraScreen({super.key, required this.poseName});

  @override
  State<AiPoseCameraScreen> createState() => _AiPoseCameraScreenState();
}

class _AiPoseCameraScreenState extends State<AiPoseCameraScreen> {
  final PoseDetectionService _poseDetectionService = PoseDetectionService();
  final ProgressService _progressService = ProgressService();
  final WebPoseDetectionService _webPoseDetectionService =
      WebPoseDetectionService();
  final FlutterTts _tts = FlutterTts();
  final Stopwatch _stopwatch = Stopwatch();

  CameraController? _controller;
  PoseAnalysisResult? _analysis;
  bool _isCameraReady = false;
  bool _isAnalyzing = true;
  bool _isProcessingFrame = false;
  bool _voiceEnabled = true;
  bool _isSaving = false;
  String? _cameraError;
  String? _analysisError;
  String? _lastSpokenFeedback;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoomLevel = 1;
  double _zoomOnScaleStart = 1;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _configureVoice();
  }

  Future<void> _configureVoice() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(0.8);
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _cameraError = null;
      _analysisError = null;
      _isCameraReady = false;
    });

    try {
      if (kIsWeb) {
        await _initializeWebPoseDetection();
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera was found on this device.');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? ImageFormatGroup.unknown
            : defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await _configureZoom(controller);
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isCameraReady = true;
      });
      await _startAnalysis(controller);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = _messageForCameraError(error);
      });
    }
  }

  Future<void> _initializeWebPoseDetection() async {
    await _webPoseDetectionService.initialize(
      onLandmarks: _processWebLandmarks,
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _analysisError = 'Live pose detection error: $message';
        });
      },
    );

    if (!mounted) return;
    _stopwatch.start();
    setState(() {
      _isCameraReady = true;
      _analysisError = null;
    });
  }

  String _messageForCameraError(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
        case 'CameraAccessDeniedWithoutPrompt':
        case 'CameraAccessRestricted':
        case 'AudioAccessDenied':
          return kIsWeb
              ? 'Camera permission is required. Allow camera access in the browser and try again.'
              : 'Camera permission is required. Please allow camera access and try again.';
        default:
          return 'Could not open the camera: ${error.description ?? error.code}';
      }
    }

    return 'Could not open the camera. Please close other camera apps and try again.';
  }

  Future<void> _configureZoom(CameraController controller) async {
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final bodySafeMaxZoom = min(maxZoom, max(minZoom, 3.0));

      _minZoom = minZoom;
      _maxZoom = bodySafeMaxZoom;
      _zoomLevel = minZoom;
      await controller.setZoomLevel(_zoomLevel);
    } catch (_) {
      _minZoom = 1;
      _maxZoom = 1;
      _zoomLevel = 1;
    }
  }

  Future<void> _startAnalysis(CameraController controller) async {
    if (!controller.supportsImageStreaming()) {
      if (mounted) {
        setState(() {
          _analysisError = kIsWeb
              ? 'Camera preview is available, but live pose detection is not supported in this browser build.'
              : 'Camera preview is available, but live pose detection is not supported on this device.';
        });
      }
      return;
    }

    _stopwatch.start();
    try {
      await controller.startImageStream((image) {
        if (!_isAnalyzing || _isProcessingFrame || !mounted) return;
        _processCameraImage(image, controller.description);
      });
      if (mounted) {
        setState(() => _analysisError = null);
      }
    } catch (error) {
      debugPrint('[AiPoseCameraScreen] Image stream failed: $error');
      if (mounted) {
        setState(() {
          _analysisError =
              'Camera is open, but live pose detection could not start on this device.';
        });
      }
    }
  }

  Future<void> _processCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    _isProcessingFrame = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final next = await _poseDetectionService.analyzeInputImage(
        poseName: widget.poseName,
        inputImage: inputImage,
      );

      if (!mounted) return;
      setState(() => _analysis = next);
      _speakFeedback(next.correctionMessages.first);
    } catch (error) {
      debugPrint('[AiPoseCameraScreen] Pose detection failed: $error');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _processWebLandmarks(List<PoseKeypoint> keypoints) {
    if (!_isAnalyzing || !mounted) return;

    final next = _poseDetectionService.analyzeLandmarks(
      poseName: widget.poseName,
      keypoints: keypoints,
    );

    setState(() {
      _analysis = next;
      _analysisError = null;
    });
    _speakFeedback(next.correctionMessages.first);
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _speakFeedback(String feedback) async {
    if (!_voiceEnabled || _lastSpokenFeedback == feedback) return;
    _lastSpokenFeedback = feedback;
    await _tts.stop();
    await _tts.speak(feedback);
  }

  void _toggleAnalysis() {
    setState(() => _isAnalyzing = !_isAnalyzing);
    if (kIsWeb) {
      _webPoseDetectionService.setAnalyzing(_isAnalyzing);
    }
    if (_isAnalyzing) {
      _stopwatch.start();
    } else {
      _stopwatch.stop();
    }
  }

  Future<void> _setZoomLevel(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final nextZoom = value.clamp(_minZoom, _maxZoom).toDouble();
    setState(() => _zoomLevel = nextZoom);

    try {
      await controller.setZoomLevel(nextZoom);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zoom is not supported on this camera.')),
      );
    }
  }

  void _zoomBy(double delta) {
    _setZoomLevel(_zoomLevel + delta);
  }

  void _fitBody() {
    _setZoomLevel(_minZoom);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomOnScaleStart = _zoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    _setZoomLevel(_zoomOnScaleStart * details.scale);
  }

  Future<void> _finishSession() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    _stopwatch.stop();
    if (!kIsWeb &&
        _controller?.supportsImageStreaming() == true &&
        _controller?.value.isStreamingImages == true) {
      await _controller?.stopImageStream();
    }

    final result = _analysis;
    final durationSeconds = _stopwatch.elapsed.inSeconds;

    if (result == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pose was detected yet. Try again.')),
      );
      await _restartImageStream();
      _stopwatch.start();
      return;
    }

    try {
      await _progressService.recordAiPoseSession(
        poseName: widget.poseName,
        accuracy: result.accuracy,
        durationSeconds: durationSeconds,
        completed: result.isComplete,
        incorrectParts: result.incorrectParts.map(_bodyPartLabel).toList(),
        statusLabel: result.statusLabel,
        feedbackMessages: result.correctionMessages,
        jointAngles: result.jointAngles,
        checkScores: result.checkScores,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${result.accuracy}% pose accuracy')),
      );
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save session: $error')));
      await _restartImageStream();
      _stopwatch.start();
    }
  }

  Future<void> _restartImageStream() async {
    if (kIsWeb) {
      _webPoseDetectionService.setAnalyzing(true);
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.supportsImageStreaming()) return;
    if (controller.value.isStreamingImages) return;
    await _startAnalysis(controller);
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        _controller?.supportsImageStreaming() == true &&
        _controller?.value.isStreamingImages == true) {
      _controller?.stopImageStream();
    }
    _controller?.dispose();
    _webPoseDetectionService.dispose();
    _poseDetectionService.close();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.poseName} AI Coach'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            tooltip: _voiceEnabled
                ? 'Disable voice guidance'
                : 'Enable voice guidance',
            onPressed: () => setState(() => _voiceEnabled = !_voiceEnabled),
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
          ),
        ],
      ),
      body: _cameraError != null
          ? _CameraError(message: _cameraError!, onRetry: _initializeCamera)
          : !_isCameraReady
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: kIsWeb
                            ? HtmlElementView(
                                viewType: _webPoseDetectionService.viewType,
                              )
                            : _CameraPreview(controller: _controller!),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SkeletonPainter(_analysis),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 12,
                        child: _AccuracyCard(
                          poseName: widget.poseName,
                          result: _analysis,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 92,
                        child: _ZoomControls(
                          zoomLevel: _zoomLevel,
                          minZoom: _minZoom,
                          maxZoom: _maxZoom,
                          onZoomChanged: _setZoomLevel,
                          onZoomIn: () => _zoomBy(0.2),
                          onZoomOut: () => _zoomBy(-0.2),
                          onFitBody: _fitBody,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 88,
                        child: _FeedbackPanel(
                          poseName: widget.poseName,
                          result: _analysis,
                        ),
                      ),
                      if (_analysisError != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 168,
                          child: _AnalysisWarning(message: _analysisError!),
                        ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 18,
                        child: _SessionControls(
                          isAnalyzing: _isAnalyzing,
                          isSaving: _isSaving,
                          onPauseResume: _toggleAnalysis,
                          onStop: _finishSession,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final width = previewSize?.height ?? 640;
    final height = previewSize?.width ?? 360;

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  final String poseName;
  final PoseAnalysisResult? result;

  const _AccuracyCard({required this.poseName, required this.result});

  @override
  Widget build(BuildContext context) {
    final current = result;
    final color = current?.statusColor ?? Colors.green;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              height: 58,
              width: 58,
              child: CircularProgressIndicator(
                value: (current?.accuracy ?? 0) / 100,
                strokeWidth: 7,
                color: color,
                backgroundColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pose Name: ${current?.poseName ?? poseName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accuracy: ${current?.accuracy ?? 0}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current?.statusLabel ?? 'Detecting pose',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final String poseName;
  final PoseAnalysisResult? result;

  const _FeedbackPanel({required this.poseName, required this.result});

  @override
  Widget build(BuildContext context) {
    final current = result;
    final parts =
        current?.incorrectParts.map(_bodyPartLabel).join(', ') ??
        'Scanning posture';
    final messages =
        current?.correctionMessages ??
        const ['Align yourself inside the frame'];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    current?.feedback ?? 'Detecting $poseName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final message in messages.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(message)),
                  ],
                ),
              ),
            Text(
              current?.incorrectParts.isEmpty == true
                  ? 'All tracked body parts are aligned.'
                  : 'Needs attention: $parts',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisWarning extends StatelessWidget {
  final String message;

  const _AnalysisWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitBody;

  const _ZoomControls({
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitBody,
  });

  @override
  Widget build(BuildContext context) {
    final canZoom = maxZoom > minZoom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _ZoomIconButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: canZoom && zoomLevel > minZoom ? onZoomOut : null,
                ),
                Expanded(
                  child: Slider(
                    value: zoomLevel.clamp(minZoom, maxZoom).toDouble(),
                    min: minZoom,
                    max: canZoom ? maxZoom : minZoom + 0.01,
                    divisions: canZoom
                        ? max(1, ((maxZoom - minZoom) * 10).round())
                        : null,
                    activeColor: Colors.green,
                    inactiveColor: Colors.green.shade100,
                    onChanged: canZoom ? onZoomChanged : null,
                  ),
                ),
                _ZoomIconButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: canZoom && zoomLevel < maxZoom ? onZoomIn : null,
                ),
                SizedBox(
                  width: compact ? 42 : 48,
                  child: Text(
                    '${zoomLevel.toStringAsFixed(1)}x',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Fit body',
                  onPressed: canZoom ? onFitBody : null,
                  icon: const Icon(Icons.fit_screen),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoomIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ZoomIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: Colors.green,
    );
  }
}

class _SessionControls extends StatelessWidget {
  final bool isAnalyzing;
  final bool isSaving;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  const _SessionControls({
    required this.isAnalyzing,
    required this.isSaving,
    required this.onPauseResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onPauseResume,
            icon: Icon(isAnalyzing ? Icons.pause : Icons.play_arrow),
            label: Text(isAnalyzing ? 'Pause' : 'Start'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isSaving ? null : onStop,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
        ),
      ],
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final PoseAnalysisResult? result;

  _SkeletonPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    final current = result;
    if (current == null || current.keypoints.isEmpty) return;

    final pointMap = {
      for (final point in current.keypoints) point.name: point.position,
    };
    final sourceBounds = _boundsFor(current.keypoints);
    final scale = min(
      size.width / sourceBounds.width,
      size.height / sourceBounds.height,
    );
    Offset transform(Offset point) {
      final dx = (size.width - sourceBounds.width * scale) / 2;
      final dy = (size.height - sourceBounds.height * scale) / 2;
      return Offset(dx + point.dx * scale, dy + point.dy * scale);
    }

    final linePaint = Paint()
      ..color = current.statusColor.withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final badPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = Colors.white;

    void drawBone(String a, String b, {bool bad = false}) {
      final start = pointMap[a];
      final end = pointMap[b];
      if (start == null || end == null) return;
      canvas.drawLine(
        transform(start),
        transform(end),
        bad ? badPaint : linePaint,
      );
    }

    final badArms = current.incorrectParts.contains(BodyPart.arms);
    final badLegs = current.incorrectParts.contains(BodyPart.legs);
    final badBack = current.incorrectParts.contains(BodyPart.back);
    final badShoulders = current.incorrectParts.contains(BodyPart.shoulders);
    final badNeck = current.incorrectParts.contains(BodyPart.neck);

    drawBone('nose', 'leftShoulder', bad: badNeck);
    drawBone('nose', 'rightShoulder', bad: badNeck);
    drawBone('leftShoulder', 'rightShoulder', bad: badShoulders);
    drawBone('leftShoulder', 'leftElbow', bad: badArms);
    drawBone('leftElbow', 'leftWrist', bad: badArms);
    drawBone('rightShoulder', 'rightElbow', bad: badArms);
    drawBone('rightElbow', 'rightWrist', bad: badArms);
    drawBone('leftShoulder', 'leftHip', bad: badBack);
    drawBone('rightShoulder', 'rightHip', bad: badBack);
    drawBone('leftHip', 'rightHip', bad: badBack);
    drawBone('leftHip', 'leftKnee', bad: badLegs);
    drawBone('leftKnee', 'leftAnkle', bad: badLegs);
    drawBone('rightHip', 'rightKnee', bad: badLegs);
    drawBone('rightKnee', 'rightAnkle', bad: badLegs);

    for (final point in current.keypoints) {
      canvas.drawCircle(transform(point.position), 5, pointPaint);
    }
  }

  Rect _boundsFor(List<PoseKeypoint> keypoints) {
    final maxX = keypoints.map((point) => point.position.dx).reduce(max);
    final maxY = keypoints.map((point) => point.position.dy).reduce(max);
    return Rect.fromLTWH(0, 0, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}

String _bodyPartLabel(BodyPart part) {
  switch (part) {
    case BodyPart.arms:
      return 'arms';
    case BodyPart.legs:
      return 'legs';
    case BodyPart.back:
      return 'back';
    case BodyPart.neck:
      return 'neck';
    case BodyPart.shoulders:
      return 'shoulders';
    case BodyPart.hips:
      return 'hips';
    case BodyPart.feet:
      return 'feet';
    case BodyPart.balance:
      return 'balance';
  }
}
