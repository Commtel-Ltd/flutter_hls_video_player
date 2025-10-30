import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'flutter_hls_video_controls.dart';
import 'flutter_hls_video_player_state.dart';

class FlutterHLSVideoPlayerController {
  final _stateController =
      StreamController<FlutterHLSVideoPlayerState>.broadcast();
  FlutterHLSVideoPlayerState _currentState = FlutterHLSVideoPlayerState();
  InAppWebViewController? _webViewController;
  final _webViewReadyCompleter = Completer<void>();
  Completer<void>? _metadataReadyCompleter;
  Stream<FlutterHLSVideoPlayerState> get stateStream => _stateController.stream;
  FlutterHLSVideoPlayerState get initialState => _currentState;
  FlutterHLSVideoPlayerState get currentState => _currentState;
  Timer? videoMetadataTimer;
  Timer? _metadataTimeoutTimer;
  DateTime? dateTime;

  void dispose() {
    _stateController.close();
    if (videoMetadataTimer != null) {
      videoMetadataTimer!.cancel();
    }
    if (_metadataTimeoutTimer != null) {
      _metadataTimeoutTimer!.cancel();
    }
  }

  void _updateState(FlutterHLSVideoPlayerState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void onWebViewCreated(InAppWebViewController controller) {
    _webViewController = controller;

    // Complete the future to signal that WebView is ready
    if (!_webViewReadyCompleter.isCompleted) {
      _webViewReadyCompleter.complete();
    }

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onBufferingStart',
      callback: (args) {
        _updateState(_currentState.copyWith(
            playbackStatus: PlaybackStatus.buffering, showControls: true));
        log("onBufferingStart Flutter");
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onBufferingEnd',
      callback: (args) {
        _updateState(
            _currentState.copyWith(playbackStatus: PlaybackStatus.playing));
        showControls(true);
        log("onBufferingEnd Flutter");
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onCanPlay',
      callback: (args) {
        _updateState(_currentState.copyWith(
            playbackStatus: PlaybackStatus.loaded, showControls: true));

        log("onCanPlay Flutter");

        // Proactively check if metadata is available when canplay fires
        // This handles cases where loadedmetadata fired before handler was registered
        _checkMetadataAvailability();
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'qualityLevels',
      callback: (args) {
        List<dynamic> levels = jsonDecode(args[0]);

        log("qualityLevels Flutter $levels");

        List<dynamic> qualityLevelAuto = [
          {"width": "Auto", "height": "Auto"},
        ];

        var availableQualities = qualityLevelAuto +
            levels
                .map((level) => {
                      "height": level["height"],
                      "width": level["width"],
                      "bitrate": level["bitrate"]
                    })
                .toList();

        _updateState(
            _currentState.copyWith(availableQualities: availableQualities));
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onError',
      callback: (args) {
        String errorMessage = args[0];
        // Log the error or update the state to show it
        log("Video Load Error: $errorMessage");

        // Update the state to show error message in the UI
        _updateState(_currentState.copyWith(
          playbackStatus: PlaybackStatus.error,
          errorMessage: errorMessage,
        ));

        // Complete the metadata completer with error to unblock any awaits
        if (_metadataReadyCompleter != null && !_metadataReadyCompleter!.isCompleted) {
          _metadataReadyCompleter!.completeError(errorMessage);
        }

        // Cancel timeout timer if running
        _metadataTimeoutTimer?.cancel();
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onMetadataLoaded',
      callback: (args) {
        log("onMetadataLoaded Flutter: $args");

        // Cancel timeout timer since metadata loaded successfully
        _metadataTimeoutTimer?.cancel();

        // Complete the metadata ready completer
        if (_metadataReadyCompleter != null && !_metadataReadyCompleter!.isCompleted) {
          _metadataReadyCompleter!.complete();
        }
      },
    );
  }

  void onError({required String message}) {
    _updateState(_currentState.copyWith(
      showControls: false,
      duration: 0,
      currentPosition: 0,
      seekPosition: 0,
      errorMessage: message,
      playbackStatus: PlaybackStatus.error,
    ));
  }

  Future<void> loadHlsVideo(String m3u8Url) async {
    try {
      if (m3u8Url == 'null' || !m3u8Url.contains('.m3u8')) {
        onError(message: "Failed to load video");
        return;
      }

      // Reset and create new metadata completer for this video load
      _metadataReadyCompleter = Completer<void>();

      // Update the state to indicate video is loading
      _updateState(_currentState.copyWith(
        showControls: true,
        duration: 0,
        currentPosition: 0,
        seekPosition: 0,
        playbackStatus: PlaybackStatus.loading,
      ));

      // Wait for WebView to be ready before attempting to load video
      await _webViewReadyCompleter.future;

      final escapedUrl = jsonEncode(m3u8Url);
      await _webViewController?.evaluateJavascript(source: '''
      hlfVideoLoad($escapedUrl);
    ''');

      // Set up a timeout for metadata loading (10 seconds)
      _metadataTimeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_metadataReadyCompleter != null && !_metadataReadyCompleter!.isCompleted) {
          log("Metadata loading timeout");
          _metadataReadyCompleter!.completeError("Video metadata loading timeout");
          onError(message: "Video failed to load - timeout");
        }
      });
    } catch (e) {
      // Update the state in case of an error
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: "loadHlsVideo ${e.toString()}",
      ));
    }
  }

  Future<void> play() async {
    try {
      // Wait for metadata to be ready before playing
      if (_metadataReadyCompleter != null && !_metadataReadyCompleter!.isCompleted) {
        try {
          await _metadataReadyCompleter!.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Metadata not ready for playback");
            },
          );
        } catch (e) {
          log("Error waiting for metadata in play(): $e");
          // Continue anyway, but this might result in 00:00/00:00
        }
      }

      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.play();
      ''');
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.playing,
      ));
      showControls(true);

      _fetchVideoMetadata();
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: "play ${e.toString()}",
      ));
    }
  }

  Future<void> pause() async {
    try {
      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.pause();
      ''');
      _updateState(_currentState.copyWith(
          playbackStatus: PlaybackStatus.paused, showControls: true));
      _stopVideoMetadata();
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleMute() async {
    try {
      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.muted = !videoE.muted;
      ''');
      _updateState(_currentState.copyWith(
        muted: !_currentState.muted,
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void seekPosition(double seek) {
    _updateState(
        _currentState.copyWith(seekPosition: seek, showControls: true));
  }

  Future<void> seekTo(double seconds) async {
    try {
      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.currentTime = $seconds;
      ''');
      _updateState(_currentState.copyWith(
        currentPosition: seconds,
      ));
      showControls(true);
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: "seekTo ${e.toString()}",
      ));
    }
  }

  Future<void> tapToSeek({bool isLeft = true}) async {
    if (isLeft) {
      _updateState(_currentState.copyWith(onLeftTapToSeek: true));
      await Future.delayed(
        const Duration(milliseconds: 1500),
      );
      _updateState(_currentState.copyWith(onLeftTapToSeek: false));
    } else {
      _updateState(_currentState.copyWith(onRightTapToSeek: true));
      await Future.delayed(
        const Duration(milliseconds: 1500),
      );
      _updateState(_currentState.copyWith(onRightTapToSeek: false));
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.volume = $volume;
      ''');
      _updateState(_currentState.copyWith(
        volume: volume,
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleFullscreen() async {
    if (_currentState.fullScreen == true) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      _updateState(_currentState.copyWith(
        fullScreen: false,
      ));
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _updateState(_currentState.copyWith(
        fullScreen: true,
      ));
    }
  }

  Future<void> changeQuality(int qualityIndex) async {
    try {
      int quality = -1;

      if (qualityIndex != -1) {
        quality = (qualityIndex - 1);
      } else {
        quality = -1;
      }

      await _webViewController?.evaluateJavascript(source: '''
        hls.currentLevel = $quality;
      ''');
      _updateState(_currentState.copyWith(
        currentQuality: qualityIndex,
      ));

      log("Here Tap quality $quality");
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateBufferPosition() async {
    try {
      final bufferedPosition = await _webViewController?.evaluateJavascript(
          source: 'document.getElementById("video").buffered.end(0)');
      _updateState(_currentState.copyWith(
        bufferedPosition: double.parse(bufferedPosition ?? '0'),
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: "updateBufferPosition ${e.toString()}",
      ));
    }
  }

  Future<void> showControls(active) async {
    dateTime = DateTime.now();
    _updateState(_currentState.copyWith(showControls: active));
  }

  Future<void> _fetchVideoMetadata() async {
    videoMetadataTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      // << Hide Video Controls
      if (_currentState.playbackStatus == PlaybackStatus.playing) {
        if (dateTime != null) {
          Duration difference = DateTime.now().difference(dateTime!);
          if (difference.inSeconds > 5) {
            showControls(false);
            dateTime = null;
          }
        }

        // >>

        try {
          final duration = await _webViewController?.evaluateJavascript(
              source: 'document.getElementById("video").duration');
          final currentPosition = await _webViewController?.evaluateJavascript(
              source: 'document.getElementById("video").currentTime');

          // Verify duration is valid before updating (not NaN, not Infinity, not 0)
          double sanitizedDuration = sanitizeDouble(duration);
          double sanitizedPosition = sanitizeDouble(currentPosition);

          // Only update if we have valid duration
          // (Check for actual numeric value, duration should be > 0 for valid videos)
          if (sanitizedDuration > 0 && !sanitizedDuration.isInfinite) {
            _updateState(
              _currentState.copyWith(
                duration: sanitizedDuration,
                currentPosition: sanitizedPosition,
                seekPosition: sanitizedPosition,
              ),
            );

            // Check for video completion
            if (_currentState.currentPosition >= _currentState.duration - 0.5) {
              _stopVideoMetadata();
              _updateState(_currentState.copyWith(
                  playbackStatus: PlaybackStatus.complete, showControls: true));
            }
          } else {
            // Duration still not valid, log it
            log("Duration not yet valid: $duration (sanitized: $sanitizedDuration)");
          }
        } catch (e) {
          log("Error in _fetchVideoMetadata: $e");
          // Don't set error state for metadata fetch failures during playback
          // as these might be transient issues
        }
      }
    });
  }

  Future<void> _stopVideoMetadata() async {
    videoMetadataTimer?.cancel();
  }

  Future<void> _checkMetadataAvailability() async {
    try {
      // Check if metadata completer exists and is not completed
      if (_metadataReadyCompleter == null || _metadataReadyCompleter!.isCompleted) {
        return;
      }

      // Try to fetch duration to see if metadata is ready
      final duration = await _webViewController?.evaluateJavascript(
          source: 'document.getElementById("video").duration');

      // If duration is valid (not NaN, not Infinity), metadata is ready
      if (duration != null) {
        double durationValue = sanitizeDouble(duration);
        if (durationValue > 0 && !durationValue.isInfinite) {
          log("Metadata detected as ready via proactive check, duration: $durationValue");
          _metadataTimeoutTimer?.cancel();
          if (!_metadataReadyCompleter!.isCompleted) {
            _metadataReadyCompleter!.complete();
          }
        }
      }
    } catch (e) {
      log("Error checking metadata availability: $e");
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await _webViewController?.evaluateJavascript(source: '''
        var videoE = document.getElementById('video');
        videoE.loop = ${mode == LoopMode.single};
      ''');
      _updateState(_currentState.copyWith(
        loopMode: mode,
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        playbackStatus: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
