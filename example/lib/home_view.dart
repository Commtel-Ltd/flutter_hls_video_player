import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_controls.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_player_controller.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_player_state.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/view/flutter_hls_video_player.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<String> demoM3u8VideoUrls = [
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.mp4/.m3u8",
    "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8",
    "https://moctobpltc-i.akamaihd.net/hls/live/571329/eight/playlist.m3u8",
    "http://d3rlna7iyyu8wu.cloudfront.net/skip_armstrong/skip_armstrong_stereo_subs.m3u8 "
  ];
  ValueNotifier<int> activeVideoIndexValueNotifier = ValueNotifier(-1);

  FlutterHLSVideoPlayerController flutterHLSVideoPlayerController =
      FlutterHLSVideoPlayerController();

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      _playVideoFromList(0);
    });
    super.initState();
  }

  void _playVideoFromList(int index) {
    activeVideoIndexValueNotifier.value = index;
    flutterHLSVideoPlayerController.loadHlsVideo(demoM3u8VideoUrls[index]);
    flutterHLSVideoPlayerController.play();
  }

  void _showPopupMenu({required BuildContext mContext}) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    FlutterHLSVideoPlayerState videoState =
        flutterHLSVideoPlayerController.initialState;

    showMenu(
      context: mContext,
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
                style: TextStyle(
                    fontWeight: videoState.currentQuality == index
                        ? FontWeight.bold
                        : null),
              ),
              onTap: () {
                flutterHLSVideoPlayerController
                    .changeQuality(index == 0 ? -1 : index);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<FlutterHLSVideoPlayerState>(
            stream: flutterHLSVideoPlayerController.stateStream,
            builder: (mContext, snapshot) {
              bool isFullScreen =
                  (snapshot.data != null && snapshot.data!.fullScreen);

              // Video Player
              return Stack(
                children: [
                  // Video Background UI For Portrate
                  if (isFullScreen == false)
                    Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.black,
                          ),
                        ),

                        // Body Content
                        Expanded(
                            child: ValueListenableBuilder<int>(
                                valueListenable: activeVideoIndexValueNotifier,
                                builder: (context, activeIndex, _) {
                                  return ListView.builder(
                                      itemCount: demoM3u8VideoUrls.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          onTap: () {
                                            _playVideoFromList(index);
                                          },
                                          title: Text(
                                            demoM3u8VideoUrls[index],
                                            style: TextStyle(
                                              color: activeIndex == index
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.white,
                                            ),
                                          ),
                                        );
                                      });
                                }))
                      ],
                    ),
                  FlutterHLSVideoPlayer(
                    controller: flutterHLSVideoPlayerController,
                    controls: FlutterHLSVideoPlayerControls(
                      hideBackArrowWidget: true,
                      onTapArrowBack: () {},
                      onTapSetting: () {
                        _showPopupMenu(mContext: context);
                      },
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  @override
  void dispose() {
    flutterHLSVideoPlayerController.dispose();
    super.dispose();
  }
}
