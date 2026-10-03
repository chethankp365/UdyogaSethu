import 'dart:math';

enum LivenessChallengeType {
  blink,
  turnLeft,
  turnRight,
  smile,
}

class LivenessChallenge {
  final LivenessChallengeType type;
  bool isCompleted;

  LivenessChallenge({
    required this.type,
    this.isCompleted = false,
  });

  String get label {
    switch (type) {
      case LivenessChallengeType.blink:
        return 'Blink both eyes slowly';
      case LivenessChallengeType.turnLeft:
        return 'Turn your head slightly to the left';
      case LivenessChallengeType.turnRight:
        return 'Turn your head slightly to the right';
      case LivenessChallengeType.smile:
        return 'Smile warmly at the camera';
    }
  }

  static List<LivenessChallenge> generateRandomPair() {
    final types = List<LivenessChallengeType>.from(LivenessChallengeType.values);
    types.shuffle(Random());
    return [
      LivenessChallenge(type: types[0]),
      LivenessChallenge(type: types[1]),
    ];
  }
}
