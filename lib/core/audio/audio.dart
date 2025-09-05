// Simple stub for audio service used by the extracted notes UI.
// In the full app this would be implemented with platform-specific plugins.

class _AudioServiceStub {
  Future<void> startRecording() async {}
  Future<String?> stopRecording() async => null;
  Future<void> play(String path) async {}
  Future<void> stop() async {}
}

dynamic createAudioService() => _AudioServiceStub();
