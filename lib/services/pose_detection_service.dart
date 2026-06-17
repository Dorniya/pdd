import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/child_pose_reference.dart';
import '../models/cobra_pose_reference.dart';
import '../models/mountain_pose_reference.dart';
import '../models/pose_analysis.dart';
import '../models/tree_pose_reference.dart';
import '../models/warrior_pose_reference.dart';

class PoseDetectionService {
  PoseDetectionService();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  Future<PoseAnalysisResult> analyzeInputImage({
    required String poseName,
    required InputImage inputImage,
  }) async {
    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) {
      return PoseAnalysisResult(
        poseName: poseName,
        accuracy: 0,
        status: PoseStatus.incorrect,
        feedback: 'Step fully into the camera frame.',
        correctionMessages: const [
          'Make sure your full body is visible in the frame.',
        ],
        incorrectParts: const [
          BodyPart.neck,
          BodyPart.shoulders,
          BodyPart.arms,
          BodyPart.back,
          BodyPart.hips,
          BodyPart.legs,
          BodyPart.feet,
          BodyPart.balance,
        ],
        keypoints: const [],
      );
    }

    final bestPose = poses.reduce((a, b) {
      return _averageLikelihood(a) >= _averageLikelihood(b) ? a : b;
    });

    final keypoints = _keypointsFromPose(bestPose);
    return _comparePose(poseName: poseName, keypoints: keypoints);
  }

  PoseAnalysisResult analyzeLandmarks({
    required String poseName,
    required List<PoseKeypoint> keypoints,
  }) {
    return _comparePose(poseName: poseName, keypoints: keypoints);
  }

  Future<void> close() => _poseDetector.close();

  PoseAnalysisResult _comparePose({
    required String poseName,
    required List<PoseKeypoint> keypoints,
  }) {
    if (poseName.toLowerCase().contains('tree')) {
      return _compareWithTreePose(keypoints: keypoints);
    }
    if (poseName.toLowerCase().contains('warrior')) {
      return _compareWithWarriorPose(keypoints: keypoints);
    }
    if (poseName.toLowerCase().contains('cobra')) {
      return _compareWithCobraPose(keypoints: keypoints);
    }
    if (poseName.toLowerCase().contains('child')) {
      return _compareWithChildPose(keypoints: keypoints);
    }

    return _compareWithMountainPose(poseName: poseName, keypoints: keypoints);
  }

  PoseAnalysisResult _compareWithMountainPose({
    required String poseName,
    required List<PoseKeypoint> keypoints,
  }) {
    final points = {for (final point in keypoints) point.name: point.position};
    final angles = _jointAngles(points);
    final checkScores = <String, int>{};
    final messages = <String>[];
    final parts = <BodyPart>{};

    int scoreCheck(
      String name,
      double value,
      double tolerance, {
      String? message,
      BodyPart? part,
    }) {
      final score = (100 - (value / tolerance * 100)).clamp(0, 100).round();
      checkScores[name] = score;
      if (score < 85) {
        if (message != null) messages.add(message);
        if (part != null) parts.add(part);
      }
      return score;
    }

    final headCenter = _xDistanceToBodyCenter(points['nose'], points);
    scoreCheck(
      'headCentered',
      headCenter,
      0.08,
      message: 'Keep your head centered.',
      part: BodyPart.neck,
    );

    final shoulderLevel = _verticalDifference(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    scoreCheck(
      'shouldersLevel',
      shoulderLevel,
      0.045,
      message: 'Keep your shoulders level.',
      part: BodyPart.shoulders,
    );

    final armsClose = _average([
      _xDistance(points['leftWrist'], points['leftHip']),
      _xDistance(points['rightWrist'], points['rightHip']),
      _xDistance(points['leftElbow'], points['leftHip']),
      _xDistance(points['rightElbow'], points['rightHip']),
    ]);
    scoreCheck(
      'armsCloseToBody',
      (armsClose - MountainPoseReference.armsCloseDistance).abs(),
      0.09,
      message: 'Keep your arms straight and close to your body.',
      part: BodyPart.arms,
    );

    final leftElbowAngle = angles['leftElbow'] ?? 0;
    final rightElbowAngle = angles['rightElbow'] ?? 0;
    final elbowError = _average([
      (180 - leftElbowAngle).abs(),
      (180 - rightElbowAngle).abs(),
    ]);
    scoreCheck(
      'elbowsStraight',
      elbowError,
      22,
      message: 'Keep both arms straight.',
      part: BodyPart.arms,
    );

    final spineLean = _spineLean(points);
    scoreCheck(
      'spineStraight',
      spineLean,
      8,
      message: 'Straighten your back.',
      part: BodyPart.back,
    );

    final hipLevel = _verticalDifference(points['leftHip'], points['rightHip']);
    scoreCheck(
      'hipsAligned',
      hipLevel,
      0.045,
      message: 'Align your hips with your shoulders.',
      part: BodyPart.hips,
    );

    final leftKneeAngle = angles['leftKnee'] ?? 0;
    final rightKneeAngle = angles['rightKnee'] ?? 0;
    final kneeError = _average([
      (180 - leftKneeAngle).abs(),
      (180 - rightKneeAngle).abs(),
    ]);
    scoreCheck(
      'kneesStraight',
      kneeError,
      18,
      message: 'Keep both knees straight.',
      part: BodyPart.legs,
    );

    final feetDistance = _xDistance(points['leftAnkle'], points['rightAnkle']);
    scoreCheck(
      'feetTogether',
      (feetDistance - MountainPoseReference.feetDistance).abs(),
      0.08,
      message: 'Bring your feet closer together.',
      part: BodyPart.feet,
    );

    final bodyBalance = _bodyBalance(points);
    scoreCheck(
      'verticalBalance',
      bodyBalance,
      0.07,
      message: 'Keep your body vertically balanced.',
      part: BodyPart.balance,
    );

    final visibilityScore = (_averageLikelihoodFromKeypoints(keypoints) * 100)
        .round();
    checkScores['landmarkVisibility'] = visibilityScore;
    if (visibilityScore < 65) {
      messages.add('Improve lighting and keep your full body visible.');
      parts.add(BodyPart.balance);
    }

    final accuracy = checkScores.values.isEmpty
        ? 0
        : (checkScores.values.reduce((a, b) => a + b) / checkScores.length)
              .round()
              .clamp(0, 100);
    final status = accuracy >= 85
        ? PoseStatus.correct
        : accuracy >= 65
        ? PoseStatus.partial
        : PoseStatus.incorrect;

    return PoseAnalysisResult(
      poseName: MountainPoseReference.poseName,
      accuracy: accuracy,
      status: status,
      feedback: accuracy >= 85
          ? 'Correct Mountain Pose ✅'
          : 'Incorrect Mountain Pose ❌',
      correctionMessages: messages.isEmpty
          ? const ['Hold steady and breathe.']
          : messages.toSet().toList(),
      incorrectParts: parts.toList(),
      keypoints: keypoints,
      jointAngles: angles,
      checkScores: checkScores,
    );
  }

  PoseAnalysisResult _compareWithTreePose({
    required List<PoseKeypoint> keypoints,
  }) {
    final points = {for (final point in keypoints) point.name: point.position};
    final angles = _jointAngles(points);
    final checkScores = <String, int>{};
    final messages = <String>[];
    final parts = <BodyPart>{};

    int scoreCheck(
      String name,
      double value,
      double tolerance, {
      String? message,
      BodyPart? part,
    }) {
      final score = (100 - (value / tolerance * 100)).clamp(0, 100).round();
      checkScores[name] = score;
      if (score < 85) {
        if (message != null) messages.add(message);
        if (part != null) parts.add(part);
      }
      return score;
    }

    final leftKneeAngle = angles['leftKnee'] ?? 0;
    final rightKneeAngle = angles['rightKnee'] ?? 0;
    final standingSide = leftKneeAngle >= rightKneeAngle ? 'left' : 'right';
    final bentSide = standingSide == 'left' ? 'right' : 'left';
    final standingKneeAngle = standingSide == 'left'
        ? leftKneeAngle
        : rightKneeAngle;
    final bentKneeAngle = bentSide == 'left' ? leftKneeAngle : rightKneeAngle;

    final referenceSimilarity = max(
      _landmarkSimilarity(points, TreePoseReference.landmarks),
      _landmarkSimilarity(
        points,
        TreePoseReference.landmarks,
        mirrorReference: true,
      ),
    );
    checkScores['referenceSimilarity'] = referenceSimilarity.round();
    if (referenceSimilarity < 82) {
      messages.add('Match the Tree Pose reference image more closely.');
      parts.add(BodyPart.balance);
    }

    scoreCheck(
      'standingLegStraight',
      (180 - standingKneeAngle).abs(),
      24,
      message: 'Keep your standing leg straight.',
      part: BodyPart.legs,
    );

    scoreCheck(
      'bentLegFolded',
      (45 - bentKneeAngle).abs(),
      45,
      message: 'Lift your bent leg higher.',
      part: BodyPart.legs,
    );

    final standingHip = points['${standingSide}Hip'];
    final standingKnee = points['${standingSide}Knee'];
    final bentAnkle = points['${bentSide}Ankle'];
    final bentFoot = points['${bentSide}FootIndex'] ?? bentAnkle;
    final innerLegDistance = _distanceToSegment(
      bentFoot,
      standingHip,
      standingKnee,
    );
    scoreCheck(
      'footOnInnerLeg',
      innerLegDistance,
      0.17,
      message: 'Place your foot against the inner thigh or calf.',
      part: BodyPart.feet,
    );

    final footHeightError = _treeFootHeightError(
      bentFoot,
      standingHip,
      standingKnee,
    );
    scoreCheck(
      'bentFootHeight',
      footHeightError,
      0.18,
      message: 'Lift your bent leg higher.',
      part: BodyPart.legs,
    );

    final spineLean = _spineLean(points);
    scoreCheck(
      'spineUpright',
      spineLean,
      10,
      message: 'Keep your spine upright.',
      part: BodyPart.back,
    );

    final headCenter = _xDistanceToBodyCenter(points['nose'], points);
    scoreCheck(
      'headCentered',
      headCenter,
      0.1,
      message: 'Keep your head centered.',
      part: BodyPart.neck,
    );

    final balanceError = _treeBalanceError(points, standingSide);
    scoreCheck(
      'bodyBalanced',
      balanceError,
      0.12,
      message: 'Maintain balance.',
      part: BodyPart.balance,
    );

    final armError = _treeArmPositionError(points, angles);
    scoreCheck(
      'armsMatchReference',
      armError,
      0.28,
      message: 'Match the arm position shown in the reference image.',
      part: BodyPart.arms,
    );

    final visibilityScore = (_averageLikelihoodFromKeypoints(keypoints) * 100)
        .round();
    checkScores['landmarkVisibility'] = visibilityScore;
    if (visibilityScore < 65) {
      messages.add('Improve lighting and keep your full body visible.');
      parts.add(BodyPart.balance);
    }

    final accuracy = checkScores.values.isEmpty
        ? 0
        : (checkScores.values.reduce((a, b) => a + b) / checkScores.length)
              .round()
              .clamp(0, 100);
    final status = accuracy >= 85
        ? PoseStatus.correct
        : accuracy >= 65
        ? PoseStatus.partial
        : PoseStatus.incorrect;

    return PoseAnalysisResult(
      poseName: TreePoseReference.poseName,
      accuracy: accuracy,
      status: status,
      feedback: accuracy >= 85
          ? 'Correct Tree Pose ✅'
          : 'Incorrect Tree Pose ❌',
      correctionMessages: messages.isEmpty
          ? const ['Hold the Tree Pose steady.']
          : messages.toSet().toList(),
      incorrectParts: parts.toList(),
      keypoints: keypoints,
      jointAngles: angles,
      checkScores: checkScores,
    );
  }

  PoseAnalysisResult _compareWithWarriorPose({
    required List<PoseKeypoint> keypoints,
  }) {
    if (!_isFullBodyVisible(keypoints)) {
      return const PoseAnalysisResult(
        poseName: WarriorPoseReference.poseName,
        accuracy: 0,
        status: PoseStatus.incorrect,
        feedback: 'Move back so your full body is visible',
        correctionMessages: ['Move back so your full body is visible'],
        incorrectParts: [
          BodyPart.neck,
          BodyPart.arms,
          BodyPart.back,
          BodyPart.hips,
          BodyPart.legs,
          BodyPart.feet,
          BodyPart.balance,
        ],
        keypoints: [],
      );
    }

    final points = {for (final point in keypoints) point.name: point.position};
    final angles = _jointAngles(points);
    final checkScores = <String, int>{};
    final messages = <String>[];
    final parts = <BodyPart>{};

    int scoreCheck(
      String name,
      double value,
      double tolerance, {
      String? message,
      BodyPart? part,
    }) {
      final score = (100 - (value / tolerance * 100)).clamp(0, 100).round();
      checkScores[name] = score;
      if (score < 85) {
        if (message != null) messages.add(message);
        if (part != null) parts.add(part);
      }
      return score;
    }

    final leftKneeAngle = angles['leftKnee'] ?? 0;
    final rightKneeAngle = angles['rightKnee'] ?? 0;
    final frontSide = leftKneeAngle <= rightKneeAngle ? 'left' : 'right';
    final backSide = frontSide == 'left' ? 'right' : 'left';
    final frontKneeAngle = frontSide == 'left' ? leftKneeAngle : rightKneeAngle;
    final backKneeAngle = backSide == 'left' ? leftKneeAngle : rightKneeAngle;

    final referenceSimilarity = max(
      _landmarkSimilarity(points, WarriorPoseReference.landmarks),
      _landmarkSimilarity(
        points,
        WarriorPoseReference.landmarks,
        mirrorReference: true,
      ),
    );
    checkScores['referenceSimilarity'] = referenceSimilarity.round();
    if (referenceSimilarity < 82) {
      messages.add('Match the Warrior Pose reference image more closely.');
      parts.add(BodyPart.balance);
    }

    scoreCheck(
      'frontKneeBent',
      (90 - frontKneeAngle).abs(),
      35,
      message: 'Bend your front knee more.',
      part: BodyPart.legs,
    );

    scoreCheck(
      'backLegStraight',
      (180 - backKneeAngle).abs(),
      24,
      message: 'Straighten your back leg.',
      part: BodyPart.legs,
    );

    final stanceWidth = _xDistance(points['leftAnkle'], points['rightAnkle']);
    scoreCheck(
      'wideStance',
      max(0, 0.68 - stanceWidth),
      0.28,
      message: 'Widen your stance.',
      part: BodyPart.feet,
    );

    final hipLevel = _verticalDifference(points['leftHip'], points['rightHip']);
    scoreCheck(
      'hipsAligned',
      hipLevel,
      0.07,
      message: 'Align your hips with your shoulders.',
      part: BodyPart.hips,
    );

    final spineLean = _spineLean(points);
    scoreCheck(
      'spineUpright',
      spineLean,
      12,
      message: 'Keep your spine upright.',
      part: BodyPart.back,
    );

    final shoulderLevel = _verticalDifference(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    scoreCheck(
      'shouldersLevel',
      shoulderLevel,
      0.06,
      message: 'Keep your shoulders level.',
      part: BodyPart.shoulders,
    );

    final armError = _warriorArmPositionError(points, angles);
    scoreCheck(
      'armsExtended',
      armError,
      0.24,
      message: 'Extend your arms fully.',
      part: BodyPart.arms,
    );

    final headError = _warriorHeadAlignmentError(points);
    scoreCheck(
      'headAligned',
      headError,
      0.16,
      message: 'Look forward and keep your head aligned.',
      part: BodyPart.neck,
    );

    final balanceError = _warriorBalanceError(points);
    scoreCheck(
      'bodyBalanced',
      balanceError,
      0.14,
      message: 'Keep your body balanced and stable.',
      part: BodyPart.balance,
    );

    final visibilityScore = (_averageLikelihoodFromKeypoints(keypoints) * 100)
        .round();
    checkScores['landmarkVisibility'] = visibilityScore;

    final accuracy = checkScores.values.isEmpty
        ? 0
        : (checkScores.values.reduce((a, b) => a + b) / checkScores.length)
              .round()
              .clamp(0, 100);
    final status = accuracy >= 85 ? PoseStatus.correct : PoseStatus.incorrect;

    return PoseAnalysisResult(
      poseName: WarriorPoseReference.poseName,
      accuracy: accuracy,
      status: status,
      feedback: accuracy >= 85
          ? 'Correct Warrior Pose ✅'
          : 'Incorrect Warrior Pose ❌',
      correctionMessages: messages.isEmpty
          ? const ['Hold the Warrior Pose steady.']
          : messages.toSet().toList(),
      incorrectParts: parts.toList(),
      keypoints: keypoints,
      jointAngles: angles,
      checkScores: checkScores,
    );
  }

  PoseAnalysisResult _compareWithCobraPose({
    required List<PoseKeypoint> keypoints,
  }) {
    if (!_hasRequiredPosePoints(keypoints)) {
      return const PoseAnalysisResult(
        poseName: CobraPoseReference.poseName,
        accuracy: 0,
        status: PoseStatus.incorrect,
        feedback: 'Incorrect Cobra Pose ❌',
        correctionMessages: ['Keep your full body visible in the frame.'],
        incorrectParts: [
          BodyPart.neck,
          BodyPart.shoulders,
          BodyPart.arms,
          BodyPart.back,
          BodyPart.hips,
          BodyPart.legs,
          BodyPart.feet,
        ],
        keypoints: [],
      );
    }

    final points = {for (final point in keypoints) point.name: point.position};
    final angles = _jointAngles(points);
    final checkScores = <String, int>{};
    final messages = <String>[];
    final parts = <BodyPart>{};

    int scoreCheck(
      String name,
      double value,
      double tolerance, {
      String? message,
      BodyPart? part,
    }) {
      final score = (100 - (value / tolerance * 100)).clamp(0, 100).round();
      checkScores[name] = score;
      if (score < 85) {
        if (message != null) messages.add(message);
        if (part != null) parts.add(part);
      }
      return score;
    }

    final similarity = _bestReferenceSimilarity(
      points,
      CobraPoseReference.landmarks,
    );
    checkScores['referenceSimilarity'] = similarity.round();
    if (similarity < 82) {
      messages.add('Match the Cobra Pose reference image more closely.');
      parts.add(BodyPart.balance);
    }

    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final kneeCenter = _midpoint(points['leftKnee'], points['rightKnee']);
    final ankleCenter = _midpoint(points['leftAnkle'], points['rightAnkle']);
    final wristCenter = _midpoint(points['leftWrist'], points['rightWrist']);
    final nose = points['nose'];

    scoreCheck(
      'lyingFaceDown',
      _lineFlatness([hipCenter, kneeCenter, ankleCenter]),
      0.18,
      message: 'Keep your hips on the floor.',
      part: BodyPart.hips,
    );

    scoreCheck(
      'palmsNearShoulders',
      _palmsNearShouldersError(points),
      0.32,
      message: 'Keep your palms near your shoulders.',
      part: BodyPart.arms,
    );

    final elbowError = _average([
      _angleDistance(
        angles['leftElbow'] ?? 0,
        CobraPoseReference.jointAngles['leftElbow']!,
      ),
      _angleDistance(
        angles['rightElbow'] ?? 0,
        CobraPoseReference.jointAngles['rightElbow']!,
      ),
    ]);
    scoreCheck(
      'armsExtended',
      elbowError,
      42,
      message: 'Straighten your arms more.',
      part: BodyPart.arms,
    );

    final chestLiftError = _verticalGap(
      hipCenter,
      shoulderCenter,
      minGap: 0.24,
    );
    scoreCheck(
      'chestLifted',
      chestLiftError,
      0.18,
      message: 'Lift your chest higher.',
      part: BodyPart.back,
    );

    scoreCheck(
      'shouldersRolledBack',
      _shoulderBackError(points),
      0.22,
      message: 'Roll your shoulders back.',
      part: BodyPart.shoulders,
    );

    scoreCheck(
      'hipsAndLegsDown',
      _lineFlatness([
        points['leftHip'],
        points['rightHip'],
        points['leftKnee'],
        points['rightKnee'],
        points['leftAnkle'],
        points['rightAnkle'],
      ]),
      0.20,
      message: 'Keep your hips on the floor.',
      part: BodyPart.hips,
    );

    final hipAngleError = _average([
      _angleDistance(
        angles['leftHip'] ?? 0,
        CobraPoseReference.jointAngles['leftHip']!,
      ),
      _angleDistance(
        angles['rightHip'] ?? 0,
        CobraPoseReference.jointAngles['rightHip']!,
      ),
    ]);
    scoreCheck(
      'smoothBackArch',
      hipAngleError,
      38,
      message: 'Maintain a smooth back arch.',
      part: BodyPart.back,
    );

    scoreCheck(
      'headUpOrForward',
      _headLiftError(nose, shoulderCenter),
      0.22,
      message: 'Extend your neck gently upward.',
      part: BodyPart.neck,
    );

    scoreCheck(
      'bodyBalanced',
      _sidePoseBalanceError([
        shoulderCenter,
        hipCenter,
        kneeCenter,
        ankleCenter,
        wristCenter,
      ]),
      0.20,
      message: 'Keep your body balanced and stable.',
      part: BodyPart.balance,
    );

    final visibilityScore = (_averageLikelihoodFromKeypoints(keypoints) * 100)
        .round();
    checkScores['landmarkVisibility'] = visibilityScore;

    final accuracy = _accuracyFrom(checkScores);
    final status = accuracy >= 85 ? PoseStatus.correct : PoseStatus.incorrect;

    return PoseAnalysisResult(
      poseName: CobraPoseReference.poseName,
      accuracy: accuracy,
      status: status,
      feedback: accuracy >= 85
          ? 'Correct Cobra Pose ✅'
          : 'Incorrect Cobra Pose ❌',
      correctionMessages: messages.isEmpty
          ? const ['Hold the Cobra Pose steady.']
          : messages.toSet().toList(),
      incorrectParts: parts.toList(),
      keypoints: keypoints,
      jointAngles: angles,
      checkScores: checkScores,
    );
  }

  PoseAnalysisResult _compareWithChildPose({
    required List<PoseKeypoint> keypoints,
  }) {
    if (!_hasRequiredPosePoints(keypoints)) {
      return const PoseAnalysisResult(
        poseName: ChildPoseReference.poseName,
        accuracy: 0,
        status: PoseStatus.incorrect,
        feedback: 'Incorrect Child\'s Pose ❌',
        correctionMessages: ['Keep your full body visible in the frame.'],
        incorrectParts: [
          BodyPart.neck,
          BodyPart.shoulders,
          BodyPart.arms,
          BodyPart.back,
          BodyPart.hips,
          BodyPart.legs,
          BodyPart.feet,
        ],
        keypoints: [],
      );
    }

    final points = {for (final point in keypoints) point.name: point.position};
    final angles = _jointAngles(points);
    final checkScores = <String, int>{};
    final messages = <String>[];
    final parts = <BodyPart>{};

    int scoreCheck(
      String name,
      double value,
      double tolerance, {
      String? message,
      BodyPart? part,
    }) {
      final score = (100 - (value / tolerance * 100)).clamp(0, 100).round();
      checkScores[name] = score;
      if (score < 85) {
        if (message != null) messages.add(message);
        if (part != null) parts.add(part);
      }
      return score;
    }

    final similarity = _bestReferenceSimilarity(
      points,
      ChildPoseReference.landmarks,
    );
    checkScores['referenceSimilarity'] = similarity.round();
    if (similarity < 82) {
      messages.add('Match the Child\'s Pose reference image more closely.');
      parts.add(BodyPart.balance);
    }

    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final kneeCenter = _midpoint(points['leftKnee'], points['rightKnee']);
    final ankleCenter = _midpoint(points['leftAnkle'], points['rightAnkle']);
    final wristCenter = _midpoint(points['leftWrist'], points['rightWrist']);
    final nose = points['nose'];

    final kneeError = _average([
      _angleDistance(
        angles['leftKnee'] ?? 0,
        ChildPoseReference.jointAngles['leftKnee']!,
      ),
      _angleDistance(
        angles['rightKnee'] ?? 0,
        ChildPoseReference.jointAngles['rightKnee']!,
      ),
    ]);
    scoreCheck(
      'kneelingPosition',
      kneeError,
      46,
      message: 'Sit back further onto your heels.',
      part: BodyPart.legs,
    );

    scoreCheck(
      'hipsOnHeels',
      _hipsToHeelsError(points),
      0.30,
      message: 'Sit back further onto your heels.',
      part: BodyPart.hips,
    );

    final hipAngleError = _average([
      _angleDistance(
        angles['leftHip'] ?? 0,
        ChildPoseReference.jointAngles['leftHip']!,
      ),
      _angleDistance(
        angles['rightHip'] ?? 0,
        ChildPoseReference.jointAngles['rightHip']!,
      ),
    ]);
    scoreCheck(
      'torsoFoldedForward',
      hipAngleError,
      42,
      message: 'Lower your torso closer to the floor.',
      part: BodyPart.back,
    );

    scoreCheck(
      'foreheadNearFloor',
      _foreheadFloorError(nose, ankleCenter),
      0.24,
      message: 'Keep your forehead closer to the ground.',
      part: BodyPart.neck,
    );

    scoreCheck(
      'armsExtendedForward',
      _childArmError(points),
      0.30,
      message: 'Extend your arms forward.',
      part: BodyPart.arms,
    );

    scoreCheck(
      'backRounded',
      _childBackCurveError(shoulderCenter, hipCenter, kneeCenter),
      0.26,
      message: 'Maintain a comfortable curved spine.',
      part: BodyPart.back,
    );

    scoreCheck(
      'relaxedShoulders',
      _verticalDifference(points['leftShoulder'], points['rightShoulder']),
      0.08,
      message: 'Relax your shoulders.',
      part: BodyPart.shoulders,
    );

    scoreCheck(
      'bodySymmetrical',
      _sidePoseBalanceError([
        shoulderCenter,
        hipCenter,
        kneeCenter,
        ankleCenter,
        wristCenter,
      ]),
      0.18,
      message: 'Keep your body relaxed and symmetrical.',
      part: BodyPart.balance,
    );

    final visibilityScore = (_averageLikelihoodFromKeypoints(keypoints) * 100)
        .round();
    checkScores['landmarkVisibility'] = visibilityScore;

    final accuracy = _accuracyFrom(checkScores);
    final status = accuracy >= 85 ? PoseStatus.correct : PoseStatus.incorrect;

    return PoseAnalysisResult(
      poseName: ChildPoseReference.poseName,
      accuracy: accuracy,
      status: status,
      feedback: accuracy >= 85
          ? 'Correct Child\'s Pose ✅'
          : 'Incorrect Child\'s Pose ❌',
      correctionMessages: messages.isEmpty
          ? const ['Hold Child\'s Pose steady and breathe.']
          : messages.toSet().toList(),
      incorrectParts: parts.toList(),
      keypoints: keypoints,
      jointAngles: angles,
      checkScores: checkScores,
    );
  }

  List<PoseKeypoint> _keypointsFromPose(Pose pose) {
    final rawPoints = <String, PoseLandmark>{};
    void add(String name, PoseLandmarkType type) {
      final landmark = pose.landmarks[type];
      if (landmark != null) rawPoints[name] = landmark;
    }

    add('nose', PoseLandmarkType.nose);
    add('leftEye', PoseLandmarkType.leftEye);
    add('rightEye', PoseLandmarkType.rightEye);
    add('leftEar', PoseLandmarkType.leftEar);
    add('rightEar', PoseLandmarkType.rightEar);
    add('leftShoulder', PoseLandmarkType.leftShoulder);
    add('rightShoulder', PoseLandmarkType.rightShoulder);
    add('leftElbow', PoseLandmarkType.leftElbow);
    add('rightElbow', PoseLandmarkType.rightElbow);
    add('leftWrist', PoseLandmarkType.leftWrist);
    add('rightWrist', PoseLandmarkType.rightWrist);
    add('leftHip', PoseLandmarkType.leftHip);
    add('rightHip', PoseLandmarkType.rightHip);
    add('leftKnee', PoseLandmarkType.leftKnee);
    add('rightKnee', PoseLandmarkType.rightKnee);
    add('leftAnkle', PoseLandmarkType.leftAnkle);
    add('rightAnkle', PoseLandmarkType.rightAnkle);
    add('leftHeel', PoseLandmarkType.leftHeel);
    add('rightHeel', PoseLandmarkType.rightHeel);
    add('leftFootIndex', PoseLandmarkType.leftFootIndex);
    add('rightFootIndex', PoseLandmarkType.rightFootIndex);

    if (rawPoints.isEmpty) return const [];

    final minX = rawPoints.values.map((point) => point.x).reduce(min);
    final maxX = rawPoints.values.map((point) => point.x).reduce(max);
    final minY = rawPoints.values.map((point) => point.y).reduce(min);
    final maxY = rawPoints.values.map((point) => point.y).reduce(max);
    final width = max(maxX - minX, 1);
    final height = max(maxY - minY, 1);

    PoseKeypoint point(String name) {
      final landmark = rawPoints[name];
      if (landmark == null) {
        return PoseKeypoint(name: name, position: Offset.zero, likelihood: 0);
      }
      return PoseKeypoint(
        name: name,
        position: Offset(
          (landmark.x - minX) / width,
          (landmark.y - minY) / height,
        ),
        likelihood: landmark.likelihood,
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

  Map<String, double> _jointAngles(Map<String, Offset> points) {
    return {
      'leftElbow': _angle(
        points['leftShoulder'],
        points['leftElbow'],
        points['leftWrist'],
      ),
      'rightElbow': _angle(
        points['rightShoulder'],
        points['rightElbow'],
        points['rightWrist'],
      ),
      'leftKnee': _angle(
        points['leftHip'],
        points['leftKnee'],
        points['leftAnkle'],
      ),
      'rightKnee': _angle(
        points['rightHip'],
        points['rightKnee'],
        points['rightAnkle'],
      ),
      'leftHip': _angle(
        points['leftShoulder'],
        points['leftHip'],
        points['leftKnee'],
      ),
      'rightHip': _angle(
        points['rightShoulder'],
        points['rightHip'],
        points['rightKnee'],
      ),
      'spineLean': _spineLean(points),
    };
  }

  double _averageLikelihood(Pose pose) {
    if (pose.landmarks.isEmpty) return 0;
    final total = pose.landmarks.values.fold<double>(
      0,
      (sum, landmark) => sum + landmark.likelihood,
    );
    return total / pose.landmarks.length;
  }

  double _averageLikelihoodFromKeypoints(List<PoseKeypoint> keypoints) {
    final tracked = keypoints.where((point) => point.likelihood > 0).toList();
    if (tracked.isEmpty) return 0;
    return tracked.fold<double>(0, (sum, point) => sum + point.likelihood) /
        tracked.length;
  }

  double _angle(Offset? a, Offset? b, Offset? c) {
    if (a == null || b == null || c == null) return 0;
    if (a == Offset.zero || b == Offset.zero || c == Offset.zero) return 0;
    final ab = a - b;
    final cb = c - b;
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = ab.distance * cb.distance;
    if (mag == 0) return 0;
    return acos((dot / mag).clamp(-1, 1)) * 180 / pi;
  }

  double _spineLean(Map<String, Offset> points) {
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    if (shoulderCenter == null || hipCenter == null) return 90;
    final dx = (shoulderCenter.dx - hipCenter.dx).abs();
    final dy = (shoulderCenter.dy - hipCenter.dy).abs();
    if (dy == 0) return 90;
    return atan(dx / dy) * 180 / pi;
  }

  double _bodyBalance(Map<String, Offset> points) {
    final head = points['nose'];
    final shoulder = _midpoint(points['leftShoulder'], points['rightShoulder']);
    final hip = _midpoint(points['leftHip'], points['rightHip']);
    final ankles = _midpoint(points['leftAnkle'], points['rightAnkle']);
    final valid = [head, shoulder, hip, ankles].whereType<Offset>().toList();
    if (valid.length < 4) return 1;
    final avgX =
        valid.fold<double>(0, (sum, point) => sum + point.dx) / valid.length;
    return valid.map((point) => (point.dx - avgX).abs()).reduce(max).toDouble();
  }

  double _landmarkSimilarity(
    Map<String, Offset> points,
    Map<String, Offset> reference, {
    bool mirrorReference = false,
  }) {
    final distances = <double>[];

    for (final entry in reference.entries) {
      final userPoint = points[entry.key];
      if (userPoint == null || userPoint == Offset.zero) continue;

      final referenceName = mirrorReference
          ? _oppositeSideName(entry.key)
          : entry.key;
      final referencePoint = reference[referenceName];
      if (referencePoint == null) continue;

      final target = mirrorReference
          ? Offset(1 - referencePoint.dx, referencePoint.dy)
          : referencePoint;
      distances.add((userPoint - target).distance);
    }

    if (distances.isEmpty) return 0;
    final meanDistance = _average(distances);
    return (100 - meanDistance / 0.28 * 100).clamp(0, 100).toDouble();
  }

  String _oppositeSideName(String name) {
    if (name.startsWith('left')) return name.replaceFirst('left', 'right');
    if (name.startsWith('right')) return name.replaceFirst('right', 'left');
    return name;
  }

  double _distanceToSegment(Offset? point, Offset? a, Offset? b) {
    if (point == null || a == null || b == null) return 1;
    if (point == Offset.zero || a == Offset.zero || b == Offset.zero) return 1;

    final ab = b - a;
    final ap = point - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) return (point - a).distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0, 1);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (point - closest).distance;
  }

  double _treeFootHeightError(Offset? foot, Offset? hip, Offset? knee) {
    if (foot == null || hip == null || knee == null) return 1;
    if (foot == Offset.zero || hip == Offset.zero || knee == Offset.zero) {
      return 1;
    }

    final top = min(hip.dy, knee.dy);
    final bottom = max(hip.dy, knee.dy);
    if (foot.dy >= top && foot.dy <= bottom) return 0;
    return min((foot.dy - top).abs(), (foot.dy - bottom).abs());
  }

  double _treeBalanceError(Map<String, Offset> points, String standingSide) {
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final standingAnkle = points['${standingSide}Ankle'];
    final head = points['nose'];
    final valid = [
      head,
      shoulderCenter,
      hipCenter,
      standingAnkle,
    ].whereType<Offset>().where((point) => point != Offset.zero).toList();

    if (valid.length < 4) return 1;
    final avgX =
        valid.fold<double>(0, (sum, point) => sum + point.dx) / valid.length;
    return valid.map((point) => (point.dx - avgX).abs()).reduce(max).toDouble();
  }

  double _treeArmPositionError(
    Map<String, Offset> points,
    Map<String, double> angles,
  ) {
    final leftWrist = points['leftWrist'];
    final rightWrist = points['rightWrist'];
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    if (leftWrist == null ||
        rightWrist == null ||
        shoulderCenter == null ||
        hipCenter == null ||
        leftWrist == Offset.zero ||
        rightWrist == Offset.zero) {
      return 1;
    }

    final wristCenter = _midpoint(leftWrist, rightWrist)!;
    final chestCenter = Offset(
      shoulderCenter.dx,
      shoulderCenter.dy + (hipCenter.dy - shoulderCenter.dy) * 0.35,
    );
    final wristsTogether = (leftWrist - rightWrist).distance;
    final handsAtChest = (wristCenter - chestCenter).distance;
    final leftElbowError =
        ((angles['leftElbow'] ?? 180) -
                TreePoseReference.jointAngles['leftElbow']!)
            .abs() /
        180;
    final rightElbowError =
        ((angles['rightElbow'] ?? 180) -
                TreePoseReference.jointAngles['rightElbow']!)
            .abs() /
        180;

    return _average([
      wristsTogether,
      handsAtChest,
      leftElbowError,
      rightElbowError,
    ]);
  }

  bool _isFullBodyVisible(List<PoseKeypoint> keypoints) {
    return _hasRequiredPosePoints(keypoints);
  }

  bool _hasRequiredPosePoints(List<PoseKeypoint> keypoints) {
    final points = {for (final point in keypoints) point.name: point};
    const requiredNames = [
      'nose',
      'leftShoulder',
      'rightShoulder',
      'leftWrist',
      'rightWrist',
      'leftHip',
      'rightHip',
      'leftKnee',
      'rightKnee',
      'leftAnkle',
      'rightAnkle',
    ];

    return requiredNames.every((name) {
      final point = points[name];
      return point != null &&
          point.position != Offset.zero &&
          point.likelihood >= 0.25;
    });
  }

  int _accuracyFrom(Map<String, int> checkScores) {
    if (checkScores.isEmpty) return 0;
    return (checkScores.values.reduce((a, b) => a + b) / checkScores.length)
        .round()
        .clamp(0, 100);
  }

  double _bestReferenceSimilarity(
    Map<String, Offset> points,
    Map<String, Offset> reference,
  ) {
    return max(
      _landmarkSimilarity(points, reference),
      _landmarkSimilarity(points, reference, mirrorReference: true),
    );
  }

  double _warriorArmPositionError(
    Map<String, Offset> points,
    Map<String, double> angles,
  ) {
    final leftShoulder = points['leftShoulder'];
    final rightShoulder = points['rightShoulder'];
    final leftWrist = points['leftWrist'];
    final rightWrist = points['rightWrist'];
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftShoulder == Offset.zero ||
        rightShoulder == Offset.zero ||
        leftWrist == Offset.zero ||
        rightWrist == Offset.zero) {
      return 1;
    }

    final shoulderY = (leftShoulder.dy + rightShoulder.dy) / 2;
    final wristLevelError = _average([
      (leftWrist.dy - shoulderY).abs(),
      (rightWrist.dy - shoulderY).abs(),
    ]);
    final wristSpreadError = max(0.0, 0.84 - _xDistance(leftWrist, rightWrist));
    final elbowError =
        _average([
          _angleDistance(angles['leftElbow'] ?? 0, 180),
          _angleDistance(angles['rightElbow'] ?? 0, 180),
        ]) /
        180;

    return _average([wristLevelError, wristSpreadError, elbowError]);
  }

  double _warriorHeadAlignmentError(Map<String, Offset> points) {
    final nose = points['nose'];
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    if (nose == null || shoulderCenter == null || nose == Offset.zero) {
      return 1;
    }
    return (nose.dy - shoulderCenter.dy).abs() * 0.35 +
        max(0, (nose.dx - shoulderCenter.dx).abs() - 0.28);
  }

  double _warriorBalanceError(Map<String, Offset> points) {
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final ankleCenter = _midpoint(points['leftAnkle'], points['rightAnkle']);
    final valid = [
      shoulderCenter,
      hipCenter,
      ankleCenter,
    ].whereType<Offset>().where((point) => point != Offset.zero).toList();
    if (valid.length < 3) return 1;

    final avgX =
        valid.fold<double>(0, (sum, point) => sum + point.dx) / valid.length;
    return valid.map((point) => (point.dx - avgX).abs()).reduce(max).toDouble();
  }

  double _angleDistance(double value, double target) {
    if (value == 0) return target.abs();
    return (target - value).abs();
  }

  double _lineFlatness(List<Offset?> points) {
    final valid = points
        .whereType<Offset>()
        .where((point) => point != Offset.zero)
        .toList();
    if (valid.length < 2) return 1;

    final meanY =
        valid.fold<double>(0, (sum, point) => sum + point.dy) / valid.length;
    return valid.map((point) => (point.dy - meanY).abs()).reduce(max);
  }

  double _palmsNearShouldersError(Map<String, Offset> points) {
    final leftWrist = points['leftWrist'];
    final rightWrist = points['rightWrist'];
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    if (leftWrist == null ||
        rightWrist == null ||
        shoulderCenter == null ||
        leftWrist == Offset.zero ||
        rightWrist == Offset.zero) {
      return 1;
    }

    final wristCenter = _midpoint(leftWrist, rightWrist)!;
    return (wristCenter.dx - shoulderCenter.dx).abs() * 0.6 +
        max(0, wristCenter.dy - shoulderCenter.dy - 0.42);
  }

  double _verticalGap(Offset? lower, Offset? upper, {required double minGap}) {
    if (lower == null || upper == null) return 1;
    if (lower == Offset.zero || upper == Offset.zero) return 1;
    return max(0, minGap - (lower.dy - upper.dy).abs());
  }

  double _shoulderBackError(Map<String, Offset> points) {
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final wristCenter = _midpoint(points['leftWrist'], points['rightWrist']);
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    if (shoulderCenter == null || wristCenter == null || hipCenter == null) {
      return 1;
    }

    final shouldersBehindWrists = max(0, wristCenter.dx - shoulderCenter.dx);
    final chestOpen = max(0, hipCenter.dy - shoulderCenter.dy);
    return max(0, 0.16 - shouldersBehindWrists) + max(0, 0.22 - chestOpen);
  }

  double _headLiftError(Offset? nose, Offset? shoulderCenter) {
    if (nose == null || shoulderCenter == null) return 1;
    if (nose == Offset.zero || shoulderCenter == Offset.zero) return 1;
    return max(0, nose.dy - shoulderCenter.dy + 0.22);
  }

  double _sidePoseBalanceError(List<Offset?> points) {
    final valid = points
        .whereType<Offset>()
        .where((point) => point != Offset.zero)
        .toList();
    if (valid.length < 3) return 1;

    final minX = valid.map((point) => point.dx).reduce(min);
    final maxX = valid.map((point) => point.dx).reduce(max);
    final minY = valid.map((point) => point.dy).reduce(min);
    final maxY = valid.map((point) => point.dy).reduce(max);
    final width = maxX - minX;
    final height = maxY - minY;
    return max(0, min(width, height) - 0.18);
  }

  double _hipsToHeelsError(Map<String, Offset> points) {
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final heelCenter =
        _midpoint(points['leftHeel'], points['rightHeel']) ??
        _midpoint(points['leftAnkle'], points['rightAnkle']);
    if (hipCenter == null || heelCenter == null) return 1;
    return max(0, (hipCenter - heelCenter).distance - 0.28);
  }

  double _foreheadFloorError(Offset? nose, Offset? ankleCenter) {
    if (nose == null || ankleCenter == null) return 1;
    if (nose == Offset.zero || ankleCenter == Offset.zero) return 1;
    return max(0, (ankleCenter.dy - nose.dy).abs() - 0.18);
  }

  double _childArmError(Map<String, Offset> points) {
    final wristCenter = _midpoint(points['leftWrist'], points['rightWrist']);
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    if (wristCenter == null || shoulderCenter == null) return 1;

    final forwardReach = (wristCenter.dx - shoulderCenter.dx).abs();
    final floorLevel = max(0.0, shoulderCenter.dy - wristCenter.dy);
    return max(0.0, 0.28 - forwardReach) + floorLevel;
  }

  double _childBackCurveError(
    Offset? shoulderCenter,
    Offset? hipCenter,
    Offset? kneeCenter,
  ) {
    if (shoulderCenter == null || hipCenter == null || kneeCenter == null) {
      return 1;
    }
    if (shoulderCenter == Offset.zero ||
        hipCenter == Offset.zero ||
        kneeCenter == Offset.zero) {
      return 1;
    }

    final torsoFold = max(0, shoulderCenter.dy - hipCenter.dy);
    final hipsAboveKnees = max(0, kneeCenter.dy - hipCenter.dy);
    return max(0, 0.02 - torsoFold) + max(0, 0.18 - hipsAboveKnees);
  }

  double _xDistanceToBodyCenter(Offset? point, Map<String, Offset> points) {
    final shoulderCenter = _midpoint(
      points['leftShoulder'],
      points['rightShoulder'],
    );
    final hipCenter = _midpoint(points['leftHip'], points['rightHip']);
    final center = _midpoint(shoulderCenter, hipCenter);
    if (point == null || center == null) return 1;
    return (point.dx - center.dx).abs();
  }

  double _xDistance(Offset? a, Offset? b) {
    if (a == null || b == null) return 1;
    if (a == Offset.zero || b == Offset.zero) return 1;
    return (a.dx - b.dx).abs();
  }

  double _verticalDifference(Offset? a, Offset? b) {
    if (a == null || b == null) return 1;
    if (a == Offset.zero || b == Offset.zero) return 1;
    return (a.dy - b.dy).abs();
  }

  Offset? _midpoint(Offset? a, Offset? b) {
    if (a == null || b == null) return null;
    if (a == Offset.zero || b == Offset.zero) return null;
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
