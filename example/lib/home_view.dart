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
    "https://firebasestorage.googleapis.com/v0/b/ip-project-7e4d1.appspot.com/o/recordings%2FE06F7B41%2F0ccbda2357421272862e0fb5b7305210_ChmO0UkWUCWhoz2Vk70WaFWB1dg2.m3u8?alt=media&token=3e39489c-746d-4caf-b675-3c898a8bee71",
    "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8?ref=developerinsider.co",
    "https://test-streams.mux.dev/dai-discontinuity-deltatre/manifest.m3u8?ref=developerinsider.co",
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
                      onDownload: () {
                        // Implement your custom download logic here
                        // This could be downloading the video, saving it to device, etc.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Download functionality called! Implement your custom download logic here.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
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
