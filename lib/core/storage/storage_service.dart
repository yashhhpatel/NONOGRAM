import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../game/models/player_profile.dart';

/// Local persistence for the player profile. Uses a single JSON blob in
/// [SharedPreferences]. Corrupted data is discarded and treated as a fresh
/// profile rather than crashing.
class StorageService {
  static const _key = 'player_profile_v1';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  PlayerProfile load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return PlayerProfile.fresh();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProfile.fromJson(json);
    } catch (_) {
      // Corrupted storage: start clean.
      return PlayerProfile.fresh();
    }
  }

  Future<void> save(PlayerProfile profile) async {
    try {
      await _prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {
      // Persistence failure is non-fatal; state remains valid in memory.
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
