import 'package:audioplayers/audioplayers.dart';

/// Manages background music playback for the bunny theme.
///
/// Usage:
///   final audio = AudioService();
///   await audio.init();        // call once at startup
///   audio.toggleMusic(true);   // enable/disable
///   audio.dispose();           // cleanup
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  AudioPlayer? _musicPlayer;
  bool _musicEnabled = false;
  bool _initialized = false;

  bool get isMusicEnabled => _musicEnabled;

  /// Initialize the audio player. Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    _musicPlayer = AudioPlayer();
    _initialized = true;
  }

  /// Enable or disable background music. If enabling and not already
  /// playing, starts the bunny theme on loop.
  Future<void> toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    if (!_initialized) return;

    if (enabled) {
      await _startMusic();
    } else {
      await _stopMusic();
    }
  }

  Future<void> _startMusic() async {
    if (_musicPlayer == null) return;
    try {
      await _musicPlayer!.play(
        AssetSource('audio/bunny_theme.wav'),
      );
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.setVolume(0.35);
    } catch (_) {
      // Audio assets may not be available on all platforms
    }
  }

  Future<void> _stopMusic() async {
    if (_musicPlayer == null) return;
    try {
      await _musicPlayer!.stop();
    } catch (_) {
      // Ignore
    }
  }

  /// Set music volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    if (_musicPlayer == null) return;
    try {
      await _musicPlayer!.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  /// Clean up resources.
  Future<void> dispose() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.dispose();
      _musicPlayer = null;
    }
    _initialized = false;
  }
}
