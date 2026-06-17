class YogaPoseInfo {
  final String title;
  final String subtitle;
  final String imagePath;
  final String description;
  final String duration;
  final List<String> benefits;
  final List<String> steps;
  final List<String> tips;

  const YogaPoseInfo({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.description,
    required this.duration,
    required this.benefits,
    required this.steps,
    required this.tips,
  });
}

const List<YogaPoseInfo> yogaPoses = [
  YogaPoseInfo(
    title: 'Mountain Pose',
    subtitle: 'Posture and breathing',
    imagePath: 'assets/images/mountain_pose.png',
    duration: '5 min',
    description:
        'A grounding standing pose that helps improve posture, balance, and calm breathing.',
    benefits: [
      'Improves body alignment',
      'Strengthens legs and core',
      'Builds steady breathing',
    ],
    steps: [
      'Stand tall with feet together or hip-width apart.',
      'Press both feet evenly into the floor.',
      'Relax your shoulders and lengthen your spine.',
      'Breathe slowly while keeping your gaze forward.',
    ],
    tips: [
      'Keep your knees soft, not locked.',
      'Imagine the crown of your head lifting upward.',
    ],
  ),
  YogaPoseInfo(
    title: 'Tree Pose',
    subtitle: 'Balance and focus',
    imagePath: 'assets/images/tree_pose.png',
    duration: '8 min',
    description:
        'A balancing pose that improves concentration, posture, and stability.',
    benefits: [
      'Improves balance',
      'Strengthens ankles and legs',
      'Builds focus and patience',
    ],
    steps: [
      'Stand in Mountain Pose.',
      'Shift weight into one foot.',
      'Place the other foot on your inner calf or thigh.',
      'Bring palms together and breathe steadily.',
    ],
    tips: [
      'Avoid pressing the foot into the knee.',
      'Look at one fixed point to balance.',
    ],
  ),
  YogaPoseInfo(
    title: 'Warrior Pose',
    subtitle: 'Strength and stamina',
    imagePath: 'assets/images/warrior_pose.png',
    duration: '10 min',
    description:
        'A powerful standing pose that strengthens legs, opens hips, and builds confidence.',
    benefits: [
      'Strengthens thighs and shoulders',
      'Opens hips and chest',
      'Improves stamina',
    ],
    steps: [
      'Step one foot back into a wide stance.',
      'Bend the front knee over the ankle.',
      'Stretch arms strongly in opposite directions.',
      'Keep your chest lifted and breathe deeply.',
    ],
    tips: [
      'Keep the front knee aligned with the toes.',
      'Press firmly through the back foot.',
    ],
  ),
  YogaPoseInfo(
    title: 'Cobra Pose',
    subtitle: 'Back strength',
    imagePath: 'assets/images/cobra_pose.png',
    duration: '7 min',
    description:
        'A gentle backbend that opens the chest and strengthens the spine.',
    benefits: [
      'Strengthens the back',
      'Opens chest and shoulders',
      'Helps reduce stiffness',
    ],
    steps: [
      'Lie on your stomach with palms under shoulders.',
      'Press tops of feet into the mat.',
      'Lift your chest gently using back strength.',
      'Keep elbows close and breathe smoothly.',
    ],
    tips: ['Do not force the backbend.', 'Keep shoulders away from your ears.'],
  ),
  YogaPoseInfo(
    title: 'Child Pose',
    subtitle: 'Rest and recovery',
    imagePath: 'assets/images/child_pose.png',
    duration: '6 min',
    description:
        'A restful pose for relaxing the back, hips, shoulders, and mind.',
    benefits: [
      'Calms the nervous system',
      'Releases back tension',
      'Gently stretches hips and thighs',
    ],
    steps: [
      'Kneel on the mat and sit back toward your heels.',
      'Fold your torso forward.',
      'Rest your forehead on the mat.',
      'Stretch arms forward or beside your body.',
    ],
    tips: [
      'Use a pillow under your forehead if needed.',
      'Let your breathing become slow and easy.',
    ],
  ),
];

YogaPoseInfo poseInfoFor(String title) {
  return yogaPoses.firstWhere(
    (pose) => pose.title == title,
    orElse: () => YogaPoseInfo(
      title: title,
      subtitle: 'Yoga practice',
      imagePath: 'assets/images/mountain_pose.png',
      duration: '10 min',
      description:
          'Practice this yoga pose to improve flexibility, balance and wellness.',
      benefits: const [
        'Supports flexibility',
        'Improves body awareness',
        'Encourages mindful breathing',
      ],
      steps: const [
        'Move slowly into the pose.',
        'Keep your breathing steady.',
        'Hold only as long as it feels comfortable.',
      ],
      tips: const ['Stop if you feel pain.', 'Practice on a stable surface.'],
    ),
  );
}
