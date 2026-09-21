import 'package:flutter/services.dart';

/// Sound effects. Currently backed by the platform system click so the game has
/// audible feedback with no bundled assets or extra plugins. The interface is
/// intentionally event-based so a full audio plugin (with distinct sound files)
/// can replace the implementation without touching call sites.
enum GameSound {
  buttonTap,
  correct,
  wrong,
  cross,
  hint,
  complete,
  reward,
  purchase,
}

class AudioService {
  const AudioService();

  void play(GameSound sound, {required bool soundEnabled}) {
    if (!soundEnabled) return;
    // A single system click is used for all cues today. Distinct samples can be
    // wired in here later per [sound].
    SystemSound.play(SystemSoundType.click);
  }
}
