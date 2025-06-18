enum LoopMode { off, single, all }

enum PlaybackStatus {
  playing,
  paused,
  loading,
  buffering,
  complete,
  loaded,
  stop,
  error,
  initial
}

class FlutterHLSVideoPlayerState {
  final PlaybackStatus playbackStatus;
  final bool muted;
  final bool fullScreen;
  final double duration;
  final double currentPosition;
  final List<dynamic>? availableQualities;
  final int? currentQuality;
  final double volume;
  final double bufferedPosition;
  final LoopMode loopMode;
  final String? errorMessage;
  final double? seekPosition;
  final bool? showControls;
  final bool? onLeftDoubleTapToSeek;
  final bool? onRightDoubleTapToSeek;

  FlutterHLSVideoPlayerState(
      {this.playbackStatus = PlaybackStatus.stop,
      this.muted = false,
      this.fullScreen = false,
      this.duration = 0.0,
      this.currentPosition = 0.0,
      this.availableQualities = const [],
      this.currentQuality = 0,
      this.volume = 1.0,
      this.bufferedPosition = 0.0,
      this.loopMode = LoopMode.off,
      this.seekPosition = 0.0,
      this.errorMessage = "",
      this.showControls = false,
      this.onLeftDoubleTapToSeek = false,
      this.onRightDoubleTapToSeek = false});
  FlutterHLSVideoPlayerState copyWith({
    PlaybackStatus? playbackStatus,
    bool? muted,
    bool? fullScreen,
    double? duration,
    double? currentPosition,
    List<dynamic>? availableQualities,
    int? currentQuality,
    double? volume,
    double? bufferedPosition,
    LoopMode? loopMode,
    double? seekPosition,
    String? errorMessage,
    bool? showControls,
    bool? onLeftDoubleTapToSeek,
    bool? onRightDoubleTapToSeek,
  }) {
    return FlutterHLSVideoPlayerState(
        playbackStatus: playbackStatus ?? this.playbackStatus,
        muted: muted ?? this.muted,
        fullScreen: fullScreen ?? this.fullScreen,
        duration: duration ?? this.duration,
        currentPosition: currentPosition ?? this.currentPosition,
        availableQualities: availableQualities ?? this.availableQualities,
        currentQuality: currentQuality ?? this.currentQuality,
        volume: volume ?? this.volume,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
        loopMode: loopMode ?? this.loopMode,
        seekPosition: seekPosition ?? this.seekPosition,
        errorMessage: errorMessage ?? this.errorMessage,
        showControls: showControls ?? this.showControls,
        onLeftDoubleTapToSeek:
            onLeftDoubleTapToSeek ?? this.onLeftDoubleTapToSeek,
        onRightDoubleTapToSeek:
            onRightDoubleTapToSeek ?? this.onRightDoubleTapToSeek);
  }
}
