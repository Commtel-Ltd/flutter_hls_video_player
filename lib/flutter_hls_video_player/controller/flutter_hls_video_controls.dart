import 'package:flutter/material.dart';

class FlutterHLSVideoPlayerControls {
  Widget? playWidget;
  Widget? pausedWidget;
  Widget? forwardWidget;
  Widget? rewindWidget;
  Widget? settingsWidget;
  Widget? arrowBackWidget;
  Widget? fullscreenWidget;
  Widget? exitFullscreenWidget;
  Widget? muteWidget;
  Widget? unMuteWidget;
  Widget? downloadWidget;
  int tapToSeekTimeInSecond;
  Function? onTapSetting;
  Function? onTapArrowBack;
  Function? onDownload;
  TextStyle? videoDurationTextStyle;
  TextStyle? currentTimeTextStyle;
  TextStyle? qualityButtonTextStyle;
  TextStyle? qualityTextStyleInPopupMenu;
  TextStyle? activeQualityTextStyleInPopupMenu;
  Color? qualityPopupBackgroundColor;
  Color? qualityButtonborderColor;
  Color? qualityButtonBackgroundColor;
  SliderThemeData? sliderThemeData;
  bool hideControls;
  bool hideBackArrowWidget;
  bool hideSettingsWidget;
  bool hideRewindWidget;
  bool hideForwardWidget;
  bool hidePlayAndPauseWidget;
  bool hideVideoDurationWidget;
  bool hideQualityWidget;
  bool hideVolumeWidget;
  bool hideFullscreenWidget;
  bool hideSeekBarWidget;
  bool hideDownloadWidget;

  FlutterHLSVideoPlayerControls(
      {this.playWidget,
      this.pausedWidget,
      this.forwardWidget,
      this.rewindWidget,
      this.settingsWidget,
      this.arrowBackWidget,
      this.fullscreenWidget,
      this.exitFullscreenWidget,
      this.tapToSeekTimeInSecond = 5,
      this.onTapSetting,
      this.onTapArrowBack,
      this.onDownload,
      this.muteWidget,
      this.unMuteWidget,
      this.downloadWidget,
      this.videoDurationTextStyle,
      this.currentTimeTextStyle,
      this.qualityButtonTextStyle,
      this.qualityTextStyleInPopupMenu,
      this.activeQualityTextStyleInPopupMenu,
      this.qualityPopupBackgroundColor,
      this.qualityButtonborderColor,
      this.qualityButtonBackgroundColor,
      this.sliderThemeData,
      this.hideControls = false,
      this.hideBackArrowWidget = false,
      this.hideSettingsWidget = false,
      this.hideRewindWidget = false,
      this.hideForwardWidget = false,
      this.hidePlayAndPauseWidget = false,
      this.hideQualityWidget = false,
      this.hideVideoDurationWidget = false,
      this.hideVolumeWidget = false,
      this.hideFullscreenWidget = false,
      this.hideSeekBarWidget = false,
      this.hideDownloadWidget = false});
}

double sanitizeDouble(dynamic value) {
  try {
    if (value == null || (value is num && (value.isNaN || value.isNegative))) {
      return 0.0;
    }
    return double.parse(value.toDouble().toStringAsFixed(1));
  } catch (e) {
    debugPrint("sanitizeDouble: $e");
    return 0.0;
  }
}

double sanitizeDoubleForSeekDuration(dynamic value,
    {double min = 0.0, double max = double.infinity}) {
  try {
    if (value == null || (value is num && (value.isNaN || value.isNegative))) {
      return 0.0;
    }

    double sanitizedValue = double.parse(value.toDouble().toStringAsFixed(1));
    return sanitizedValue.clamp(min, max); // Ensure value stays within range
  } catch (e) {
    debugPrint("sanitizeDoubleForSeekDuration: $e");
    return 0.0;
  }
}
