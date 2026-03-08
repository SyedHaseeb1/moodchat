import 'dart:async';
import '../core/logger.dart';
import '../domain/repositories/profile_repository.dart';

/// Sends a heartbeat (last_seen) ping to Supabase every [intervalSeconds] seconds
/// so that other users can derive the local user's online status in real-time.
///
/// Online = last_seen within the last 40 seconds.
/// Heartbeat fires every 30 seconds so there is comfortable overlap.
class PresenceService {
  final ProfileRepository _profileRepository;

  static const int intervalSeconds = 30;

  Timer? _timer;
  String? _userId;
  bool _isRunning = false;

  PresenceService(this._profileRepository);

  /// Start heartbeat for [userId]. Fires immediately, then every [intervalSeconds].
  void start(String userId) {
    if (_isRunning && _userId == userId) return; // already running for same user
    stop(); // cancel any existing timer

    _userId = userId;
    _isRunning = true;

    AppLogger.i('PresenceService: Starting heartbeat for $userId');
    _ping(); // immediate first ping
    _timer = Timer.periodic(const Duration(seconds: intervalSeconds), (_) {
      _ping();
    });
  }

  /// Pause the heartbeat (e.g., app goes to background).
  /// Does NOT set offline — the 40s threshold handles that naturally.
  void pause() {
    if (!_isRunning) return;
    AppLogger.i('PresenceService: Pausing heartbeat for $_userId');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Resume the heartbeat (e.g., app comes back to foreground).
  void resume() {
    if (_userId == null || _userId!.isEmpty) return;
    AppLogger.i('PresenceService: Resuming heartbeat for $_userId');
    start(_userId!);
  }

  /// Stop the heartbeat completely (called on sign-out).
  void stop() {
    AppLogger.i('PresenceService: Stopping heartbeat for $_userId');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _userId = null;
  }

  bool get isRunning => _isRunning;

  Future<void> _ping() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      await _profileRepository.updateLastSeen(_userId!);
      AppLogger.d('PresenceService: Heartbeat ping sent for $_userId');
    } catch (e) {
      AppLogger.e('PresenceService: Heartbeat ping failed', e);
    }
  }
}
