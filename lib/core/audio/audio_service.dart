/// Sound/haptics playback boundary. No audio assets exist yet, so the
/// only implementation is a no-op stub — swap in a real player later
/// without touching call sites.
abstract class AudioService {
  Future<void> playCorrectGuess();
  Future<void> playWrongGuess();
  Future<void> playReveal();
}

class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  Future<void> playCorrectGuess() async {}

  @override
  Future<void> playWrongGuess() async {}

  @override
  Future<void> playReveal() async {}
}
