import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:universal_html/html.dart' as html;

import '../../../models/config/editor/image/image_web.dart';
import '../../../utils/utils.dart';
import '../../../utils/web_utils.dart';
import '../shims/dart_ui_fake.dart'
    if (dart.library.html) '../shims/dart_ui_real.dart' as ui;

class QuillEditorWebImageEmbedBuilder extends EmbedBuilder {
  const QuillEditorWebImageEmbedBuilder({
    required this.configurations,
  });

  final QuillEditorWebImageEmbedConfigurations configurations;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    assert(kIsWeb, 'ImageEmbedBuilderWeb is only for web platform');

    final WebUtilsArgs webUtilsArgs = getWebElementAttributes(node);

    var imageSource = node.value.data.toString();

    // This logic make sure if the image is imageBase64 then
    // it make sure if the pattern is like
    // data:image/png;base64, [base64 encoded image string here]
    // if not then it will add the data:image/png;base64, at the first
    if (isImageBase64(imageSource)) {
      // Sometimes the image base 64 for some reasons
      // doesn't displayed with the
      if (!(imageSource.startsWith('data:image/') &&
          imageSource.contains('base64'))) {
        imageSource = 'data:image/png;base64, $imageSource';
      }
    }

    ui.PlatformViewRegistry().registerViewFactory(imageSource, (viewId) {
      return html.ImageElement()
        ..src = imageSource
        ..style.height = webUtilsArgs.height
        ..style.width = webUtilsArgs.width
        ..style.margin = webUtilsArgs.margin
        ..style.alignSelf = webUtilsArgs.alignment
        ..attributes['loading'] = 'lazy';
    });

    return ConstrainedBox(
      constraints: configurations.constraints ??
          BoxConstraints.loose(const Size(200, 200)),
      child: HtmlElementView(
        viewType: imageSource,
      ),
    );
  }
}
