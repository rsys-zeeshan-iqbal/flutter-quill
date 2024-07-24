import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart' as base;
import 'package:flutter_quill/flutter_quill.dart';

import '../../../models/config/editor/video/video.dart';
import '../../../utils/utils.dart';
import '../../widgets/video_app.dart';
import '../../widgets/youtube_video_app.dart';

class QuillEditorVideoEmbedBuilder extends EmbedBuilder {
  const QuillEditorVideoEmbedBuilder({
    required this.configurations,
  });

  final QuillEditorVideoEmbedConfigurations configurations;

  @override
  String get key => BlockEmbed.videoType;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    base.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    assert(!kIsWeb, 'Please provide video EmbedBuilder for Web');

    final videoUrl = node.value.data;
    if (isYouTubeUrl(videoUrl)) {
      return YoutubeVideoApp(
        videoUrl: videoUrl,
        context: context,
        readOnly: readOnly,
      );
    }
    final FlutterQuillUtilsArgs flutterQuillUtilsArgs = getElementAttributes(node);

    final width =flutterQuillUtilsArgs. elementSize?.width;
    final height = flutterQuillUtilsArgs.elementSize?.height;
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.all(flutterQuillUtilsArgs.margin ?? 0.0),
      alignment:flutterQuillUtilsArgs. alignment,
      child: VideoApp(
        videoUrl: videoUrl,
        context: context,
        readOnly: readOnly,
        onVideoInit: configurations.onVideoInit,
      ),
    );
  }
}
