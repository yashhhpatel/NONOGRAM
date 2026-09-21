import 'package:flutter/services.dart';

/// Thin wrapper over the platform haptics. Respects the player's setting; the
/// caller passes the current enabled flag so this stays stateless.
class HapticsService {
  const HapticsService();

  void cellSelect(bool enabled) {
    if (enabled) HapticFeedback.selectionClick();
  }

  void lightTap(bool enabled) {
    if (enabled) HapticFeedback.lightImpact();
  }

  void wrong(bool enabled) {
    if (enabled) HapticFeedback.heavyImpact();
  }

  void complete(bool enabled) {
    if (enabled) HapticFeedback.mediumImpact();
  }

  void reward(bool enabled) {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
