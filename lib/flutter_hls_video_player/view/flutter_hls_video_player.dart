import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_controls.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/widgets/seek_arrow_animation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../animation/fade.dart';
import '../controller/flutter_hls_video_player_controller.dart';
import '../controller/flutter_hls_video_player_state.dart';
import 'hls_video_player_html.dart';

class FlutterHLSVideoPlayer extends StatefulWidget {
  final FlutterHLSVideoPlayerController controller;
  final FlutterHLSVideoPlayerControls? controls;
  const FlutterHLSVideoPlayer(
      {super.key, required this.controller, this.controls});

  @override
  State<FlutterHLSVideoPlayer> createState() => _FlutterHLSVideoPlayerState();
}

class _FlutterHLSVideoPlayerState extends State<FlutterHLSVideoPlayer> {
  FlutterHLSVideoPlayerController? flutterHLSVideoPlayerController;
  late final FlutterHLSVideoPlayerControls controls;
  final ValueNotifier<bool> showSeekAnimation = ValueNotifier(false);

  @override
  void initState() {
    flutterHLSVideoPlayerController = widget.controller;
    controls = widget.controls ?? FlutterHLSVideoPlayerControls();
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _showPopupMenu({required BuildContext mContext}) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    FlutterHLSVideoPlayerState videoState = widget.controller.initialState;

    showMenu(
      context: mContext,
      color: widget.controls?.qualityPopupBackgroundColor ?? Colors.black,
      position: RelativeRect.fromLTRB(overlay.size.width - 50, 100, 10, 0),
      items: [
        PopupMenuItem(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate((videoState.availableQualities ?? []).length,
              (index) {
            return ListTile(
              selected: videoState.currentQuality == index,
              title: Text(
                videoState.availableQualities![index]['height'] == "Auto"
                    ? videoState.availableQualities![index]['height']
                    : "${videoState.availableQualities![index]['height']} P",
                style: videoState.currentQuality == index
                    ? (widget.controls?.activeQualityTextStyleInPopupMenu ??
                        TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold))
                    : (widget.controls?.qualityTextStyleInPopupMenu ??
                        const TextStyle(
                          color: Colors.white,
                        )),
              ),
              onTap: () {
                widget.controller.changeQuality(index == 0 ? -1 : index);
                Navigator.pop(context);
              },
            );
          }),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: mediaQuery.orientation == Orientation.portrait
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      child: AspectRatio(
        aspectRatio:
            mediaQuery.orientation == Orientation.portrait ? 16 / 9 : 19 / 9,
        child: StreamBuilder<FlutterHLSVideoPlayerState>(
            stream: flutterHLSVideoPlayerController!.stateStream,
            builder: (context, snapshot) {
              double maxDuration = sanitizeDouble(snapshot.data?.duration);
              if (snapshot.hasError) {
                return Container(
                  color: Colors.black,
                );
              }
              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.black,
                        ),

                        Container(child: videoPlayerView()),

                        if (widget.controls?.hideControls == false)
                          GestureDetector(
                            onTap: () {
                              if (snapshot.data != null &&
                                  snapshot.data?.playbackStatus !=
                                      PlaybackStatus.error) {
                                flutterHLSVideoPlayerController
                                    ?.showControls(true);
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),

                        // On loading back press
                        if (widget.controls?.hideControls == false)
                          if (widget.controls?.hideBackArrowWidget == false)
                            if (snapshot.data?.playbackStatus == null ||
                                snapshot.data?.playbackStatus ==
                                    PlaybackStatus.loading)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  child:
                                      (widget.controls?.arrowBackWidget != null)
                                          ? widget.controls!.arrowBackWidget!
                                          : IconButton(
                                              onPressed: () {
                                                if (widget.controls!
                                                        .onTapArrowBack !=
                                                    null) {
                                                  widget.controls
                                                      ?.onTapArrowBack!();
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.arrow_back_ios,
                                                color: Colors.white,
                                              )),
                                ),
                              ),

                        // On Video Error
                        if (widget.controls?.hideControls == false)
                          if (snapshot.data != null &&
                              snapshot.data?.playbackStatus ==
                                  PlaybackStatus.error)
                            SizedBox(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                direction: Axis.vertical,
                                children: [
                                  Text(
                                    "${snapshot.data?.errorMessage}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.replay,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),

                        if (widget.controls?.hideControls == false)
                          FadeAnimationWidget(
                            isVisible: (snapshot.data?.showControls == true),
                            child: videoPlayerControl(mediaQuery),
                          ),
                      ],
                    ),
                  ),

                  // Video Seek Slider
                  if (widget.controls?.hideControls == false)
                    FadeAnimationWidget(
                      isVisible: (snapshot.data?.showControls == true),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Wrap(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                    left: 15, right: 10, bottom: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    (widget.controls?.hideVideoDurationWidget ==
                                            true)
                                        ? const SizedBox()
                                        : Row(
                                            children: [
                                              Text(
                                                "${_formatVideoTime(snapshot.data?.currentPosition ?? 0)} /",
                                                style: (widget
                                                            .controls?.currentTimeTextStyle !=
                                                        null)
                                                    ? widget.controls
                                                        ?.currentTimeTextStyle
                                                    : const TextStyle(
                                                        color: Colors.white),
                                              ),
                                              Text(
                                                " ${_formatVideoTime(snapshot.data?.duration ?? 0)}",
                                                style: (widget.controls
                                                            ?.videoDurationTextStyle !=
                                                        null)
                                                    ? widget.controls
                                                        ?.videoDurationTextStyle
                                                    : const TextStyle(
                                                        color:
                                                            Color(0xffC0C1C4)),
                                              ),
                                            ],
                                          ),
                                    Row(
                                      children: [
                                        // Video Quality Button
                                        if (widget
                                                .controls?.hideQualityWidget ==
                                            false)
                                          if ((snapshot.data
                                                      ?.availableQualities ??
                                                  [])
                                              .isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                _showPopupMenu(
                                                    mContext: context);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                decoration: BoxDecoration(
                                                    color: widget.controls
                                                            ?.qualityButtonBackgroundColor ??
                                                        Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                    border: Border.all(
                                                        color: widget.controls
                                                                ?.qualityButtonborderColor ??
                                                            Colors.white)),
                                                child: Text(
                                                  (snapshot.data!.currentQuality! ==
                                                              -1 ||
                                                          ("${snapshot.data?.availableQualities![snapshot.data!.currentQuality!]["height"]}"
                                                                  .toLowerCase()) ==
                                                              "auto")
                                                      ? "Auto"
                                                      : "${snapshot.data?.availableQualities![snapshot.data!.currentQuality!]["height"]} P",
                                                  style: widget.controls
                                                          ?.qualityButtonTextStyle ??
                                                      const TextStyle(
                                                          color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        SizedBox(
                                          width: mediaQuery.size.width * 0.02,
                                        ),
                                        // Mute Toggle
                                        (widget.controls?.hideVolumeWidget ==
                                                true)
                                            ? const SizedBox()
                                            : GestureDetector(
                                                onTap: () {
                                                  flutterHLSVideoPlayerController
                                                      ?.toggleMute();
                                                },
                                                child: (widget.controls?.muteWidget != null &&
                                                        widget.controls
                                                                ?.muteWidget !=
                                                            null &&
                                                        snapshot.data?.muted ==
                                                            false)
                                                    ? widget
                                                        .controls?.unMuteWidget!
                                                    : (widget.controls
                                                                    ?.muteWidget !=
                                                                null &&
                                                            widget.controls
                                                                    ?.muteWidget !=
                                                                null &&
                                                            snapshot.data
                                                                    ?.muted ==
                                                                true)
                                                        ? widget.controls
                                                            ?.muteWidget
                                                        : Icon(
                                                            snapshot.data?.muted ==
                                                                    false
                                                                ? Icons
                                                                    .volume_up
                                                                : Icons
                                                                    .volume_off,
                                                            color:
                                                                Colors.white),
                                              ),
                                        SizedBox(
                                          width: mediaQuery.size.width * 0.02,
                                        ),

                                        // Full Screen Toggle
                                        (widget.controls?.hideVolumeWidget ==
                                                true)
                                            ? const SizedBox()
                                            : GestureDetector(
                                                onTap: () {
                                                  flutterHLSVideoPlayerController
                                                      ?.toggleFullscreen();
                                                },
                                                child: (widget.controls?.exitFullscreenWidget != null &&
                                                        widget.controls
                                                                ?.fullscreenWidget !=
                                                            null &&
                                                        snapshot.data
                                                                ?.fullScreen ==
                                                            false)
                                                    ? widget.controls
                                                        ?.fullscreenWidget!
                                                    : (widget.controls?.exitFullscreenWidget !=
                                                                null &&
                                                            widget.controls
                                                                    ?.fullscreenWidget !=
                                                                null &&
                                                            snapshot.data
                                                                    ?.fullScreen ==
                                                                true)
                                                        ? widget.controls
                                                            ?.exitFullscreenWidget!
                                                        : Icon(
                                                            snapshot.data?.fullScreen ==
                                                                    false
                                                                ? Icons
                                                                    .fullscreen
                                                                : Icons
                                                                    .fullscreen_exit,
                                                            color:
                                                                Colors.white),
                                              ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          (widget.controls?.hideSeekBarWidget == true)
                              ? const SizedBox()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          mediaQuery.size.width * 0.016),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SliderTheme(
                                          data: widget.controls
                                                      ?.sliderThemeData !=
                                                  null
                                              ? widget
                                                  .controls!.sliderThemeData!
                                              : SliderTheme.of(context)
                                                  .copyWith(
                                                  inactiveTrackColor: Colors
                                                      .grey
                                                      .withOpacity(0.2),
                                                  trackHeight: 4.0,
                                                  trackShape:
                                                      _SliderCustomTrackShape(),
                                                  thumbShape:
                                                      const RoundSliderThumbShape(
                                                          enabledThumbRadius:
                                                              7.0),
                                                  overlayShape:
                                                      SliderComponentShape
                                                          .noThumb,
                                                ),
                                          child: Slider(
                                            value:
                                                sanitizeDoubleForSeekDuration(
                                                    snapshot.data?.seekPosition,
                                                    min: 0,
                                                    max: maxDuration),
                                            max: maxDuration,
                                            onChangeStart: (value) {
                                              flutterHLSVideoPlayerController
                                                  ?.pause();
                                            },
                                            onChanged: (double value) {
                                              flutterHLSVideoPlayerController
                                                  ?.seekPosition(value);
                                            },
                                            onChangeEnd: (double value) async {
                                              await flutterHLSVideoPlayerController
                                                  ?.seekTo(value);
                                              flutterHLSVideoPlayerController
                                                  ?.play();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          if (snapshot.data?.fullScreen ?? false)
                            SizedBox(
                              height: mediaQuery.size.width * 0.07,
                            )
                        ],
                      ),
                    )
                ],
              );
            }),
      ),
    );
  }

  Widget videoPlayerView() {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: htmlDataPlayer,
        mimeType: "text/html",
        encoding: "utf-8",
        baseUrl: WebUri.uri(Uri.parse("https://localhost/")),
      ),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        javaScriptEnabled: true,
        allowUniversalAccessFromFileURLs: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) {
        flutterHLSVideoPlayerController?.onWebViewCreated(controller);
      },
      onEnterFullscreen: (controller) {},
      onExitFullscreen: (controller) {},
      onReceivedHttpError: (controller, request, errorResponse) {
        flutterHLSVideoPlayerController?.onError(
            message: "Failed to load video");
      },
    );
  }

  Widget videoPlayerControl(MediaQueryData mediaQueryData) {
    return StreamBuilder<FlutterHLSVideoPlayerState>(
        stream: flutterHLSVideoPlayerController?.stateStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var state = snapshot.data;

            return Container(
              color: Colors.black.withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (widget.controls?.hideBackArrowWidget == true)
                          ? const SizedBox()
                          : GestureDetector(
                              onTap: () {
                                if (widget.controls!.onTapArrowBack != null) {
                                  widget.controls?.onTapArrowBack!();
                                }
                              },
                              child: (widget.controls?.arrowBackWidget != null)
                                  ? widget.controls!.arrowBackWidget
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.white,
                                      ),
                                    )),
                      (widget.controls?.hideSettingsWidget == true)
                          ? const SizedBox()
                          : GestureDetector(
                              onTap: () {
                                if (controls.onTapSetting != null) {
                                  controls.onTapSetting!();
                                }
                              },
                              child: (controls.settingsWidget != null)
                                  ? controls.settingsWidget!
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(Icons.settings,
                                          color: Colors.white)),
                            ),
                    ],
                  ),

                  // Center
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state?.playbackStatus == PlaybackStatus.loading ||
                          state?.playbackStatus == PlaybackStatus.buffering)
                        const CircularProgressIndicator(),
                      if (state?.playbackStatus == PlaybackStatus.playing ||
                          state?.playbackStatus == PlaybackStatus.paused ||
                          state?.playbackStatus == PlaybackStatus.stop ||
                          state?.playbackStatus == PlaybackStatus.loaded)
                        Container(
                          width: mediaQueryData.size.width,
                          padding: EdgeInsets.symmetric(
                              horizontal: mediaQueryData.size.width * 0.03),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Rewind
                              if (state?.onLeftTapToSeek == false)
                                (controls.hideRewindWidget == true)
                                    ? const SizedBox()
                                    : GestureDetector(
                                        onTap: () async {
                                          widget.controller
                                              .tapToSeek(isLeft: true);
                                          await widget.controller.seekTo((snapshot
                                                      .data?.currentPosition ??
                                                  0) -
                                              widget.controls!
                                                  .tapToSeekTimeInSecond);
                                          widget.controller.play();
                                        },
                                        child: Container(
                                            width: mediaQueryData.size.width *
                                                0.23,
                                            height: mediaQueryData.size.height *
                                                0.13,
                                            alignment: Alignment.centerRight,
                                            child: (controls.rewindWidget !=
                                                    null)
                                                ? controls.rewindWidget!
                                                : const Icon(
                                                    size: 28.0,
                                                    Icons
                                                        .keyboard_double_arrow_left,
                                                    color: Colors.white))),

                              // Double Tap to  seek animation

                              if (state?.onLeftTapToSeek == true)
                                SizedBox(
                                  width: mediaQueryData.size.width * 0.23,
                                  height: mediaQueryData.size.height * 0.13,
                                  child: const SeekArrowAnimation(
                                    isLeft: true,
                                  ),
                                ),

                              SizedBox(
                                width: mediaQueryData.size.width * 0.13,
                              ),

                              // Play / Paused

                              widget.controls!.hidePlayAndPauseWidget == true
                                  ? SizedBox(
                                      width: mediaQueryData.size.width * 0.08,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(15),
                                      child: GestureDetector(
                                          onTap: () {
                                            state?.playbackStatus ==
                                                    PlaybackStatus.playing
                                                ? flutterHLSVideoPlayerController
                                                    ?.pause()
                                                : flutterHLSVideoPlayerController
                                                    ?.play();
                                          },
                                          child: (state?.playbackStatus ==
                                                      PlaybackStatus.playing &&
                                                  widget.controls
                                                          ?.pausedWidget !=
                                                      null)
                                              ? widget.controls?.pausedWidget
                                              : (state?.playbackStatus ==
                                                          PlaybackStatus
                                                              .paused &&
                                                      widget.controls
                                                              ?.playWidget !=
                                                          null)
                                                  ? widget.controls?.playWidget
                                                  : state?.playbackStatus ==
                                                          PlaybackStatus.paused
                                                      ? const Icon(
                                                          Icons.play_arrow,
                                                          size: 28.0,
                                                          color: Colors.white)
                                                      : const Icon(Icons.pause,
                                                          size: 28.0,
                                                          color: Colors.white)),
                                    ),

                              SizedBox(
                                width: mediaQueryData.size.width * 0.13,
                              ),

                              // Forward
                              if (state?.onRightTapToSeek == false)
                                (controls.hideForwardWidget == true)
                                    ? const SizedBox()
                                    : GestureDetector(
                                        onTap: () async {
                                          widget.controller
                                              .tapToSeek(isLeft: false);
                                          await widget.controller.seekTo((snapshot
                                                      .data?.currentPosition ??
                                                  0) +
                                              widget.controls!
                                                  .tapToSeekTimeInSecond);
                                          widget.controller.play();
                                        },
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          width:
                                              mediaQueryData.size.width * 0.23,
                                          height:
                                              mediaQueryData.size.height * 0.13,
                                          child: (controls.forwardWidget !=
                                                  null)
                                              ? controls.rewindWidget!
                                              : const Icon(
                                                  Icons
                                                      .keyboard_double_arrow_right,
                                                  size: 28.0,
                                                  color: Colors.white),
                                        )),

                              // Double Tap to  seek animation

                              if (state?.onRightTapToSeek == true)
                                SizedBox(
                                  width: mediaQueryData.size.width * 0.23,
                                  height: mediaQueryData.size.height * 0.13,
                                  child: const SeekArrowAnimation(
                                    isLeft: false,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (state?.playbackStatus == PlaybackStatus.complete)
                        IconButton(
                          icon: const Icon(Icons.replay, color: Colors.white),
                          onPressed: () {
                            flutterHLSVideoPlayerController?.play();
                          },
                        ),
                    ],
                  ),

                  // Bottom

                  Wrap(children: [
                    Container(
                      height: 25,
                    )
                  ])
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return Container();
          }
        });
  }
}

String _formatVideoTime(double seconds) {
  if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
    return "00:00"; // Return default "00:00" if invalid
  }
  final int hrs = seconds ~/ 3600;
  final int mins = (seconds % 3600) ~/ 60;
  final int secs = (seconds % 60).toInt();

  if (hrs > 0) {
    // Format as hh:mm:ss
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    // Format as mm:ss
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _SliderCustomTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4.0;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 0,
    Offset? secondaryOffset,
  }) {
    if (sliderTheme.trackHeight == null ||
        sliderTheme.activeTrackColor == null ||
        sliderTheme.inactiveTrackColor == null) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor!;
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!;

    // Determine the active and inactive track areas based on the thumb's position
    final double activeTrackEnd = thumbCenter.dx;

    // Active track
    context.canvas.drawRect(
      Rect.fromLTRB(
          trackRect.left, trackRect.top, activeTrackEnd, trackRect.bottom),
      activePaint,
    );

    // Inactive track
    context.canvas.drawRect(
      Rect.fromLTRB(
          activeTrackEnd, trackRect.top, trackRect.right, trackRect.bottom),
      inactivePaint,
    );
  }
}
