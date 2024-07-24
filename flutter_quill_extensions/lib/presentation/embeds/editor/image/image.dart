import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart' as base;
import 'package:flutter_quill/flutter_quill.dart' hide OptionalSize;

import '../../../../logic/models/config/shared_configurations.dart';
import '../../../models/config/editor/image/image.dart';
import '../../../utils/utils.dart';
import '../../widgets/image.dart';
import 'image_menu.dart';

class QuillEditorImageEmbedBuilder extends EmbedBuilder {
  QuillEditorImageEmbedBuilder({
    required this.configurations,
  });
  final QuillEditorImageEmbedConfigurations configurations;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    base.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    assert(!kIsWeb, 'Please provide image EmbedBuilder for Web');

    final imageSource = standardizeImageUrl(node.value.data);
    final FlutterQuillUtilsArgs flutterQuillUtilsArgs =
        getElementAttributes(node);

    final width = flutterQuillUtilsArgs.elementSize?.width;
    final height = flutterQuillUtilsArgs.elementSize?.height;

    final image = getImageWidgetByImageSource(
      imageSource,
      imageProviderBuilder: configurations.imageProviderBuilder,
      imageErrorWidgetBuilder: configurations.imageErrorWidgetBuilder,
      alignment: flutterQuillUtilsArgs.alignment ?? Alignment.center,
      height: height,
      width: width,
      assetsPrefix: QuillSharedExtensionsConfigurations.get(context: context)
          .assetsPrefix,
    );

    // OptionalSize? imageSize;
    // final style = node.style.attributes['style'];

    // if (style != null) {
    //   final attrs = base.isMobile(supportWeb: false)
    //       ? base.parseKeyValuePairs(style.value.toString(), {
    //           Attribute.mobileWidth,
    //           Attribute.mobileHeight,
    //           Attribute.mobileMargin,
    //           Attribute.mobileAlignment,
    //         })
    //       : base.parseKeyValuePairs(style.value.toString(), {
    //           Attribute.width.key,
    //           Attribute.height.key,
    //           Attribute.margin,
    //           Attribute.alignment,
    //         });
    //   if (attrs.isNotEmpty) {
    //     final width = double.tryParse(
    //       (base.isMobile(supportWeb: false)
    //               ? attrs[Attribute.mobileWidth]
    //               : attrs[Attribute.width.key]) ??
    //           '',
    //     );
    //     final height = double.tryParse(
    //       (base.isMobile(supportWeb: false)
    //               ? attrs[Attribute.mobileHeight]
    //               : attrs[Attribute.height.key]) ??
    //           '',
    //     );
    //     final alignment = base.getAlignment(base.isMobile(supportWeb: false)
    //         ? attrs[Attribute.mobileAlignment]
    //         : attrs[Attribute.alignment]);
    //     final margin = (base.isMobile(supportWeb: false)
    //             ? double.tryParse(Attribute.mobileMargin)
    //             : double.tryParse(Attribute.margin)) ??
    //         0.0;

    //     imageSize = OptionalSize(width, height);
    //     image = Padding(
    //       padding: EdgeInsets.all(margin),
    //       child: getImageWidgetByImageSource(
    //         imageSource,
    //         width: width,
    //         height: height,
    //         alignment: alignment,
    //         imageProviderBuilder: configurations.imageProviderBuilder,
    //         imageErrorWidgetBuilder: configurations.imageErrorWidgetBuilder,
    //       ),
    //     );
    //   }
    // }

    // if (imageSize == null) {
    //   image = getImageWidgetByImageSource(
    //     imageSource,
    //     imageProviderBuilder: configurations.imageProviderBuilder,
    //     imageErrorWidgetBuilder: configurations.imageErrorWidgetBuilder,
    //   );
    //   imageSize = OptionalSize((image as Image).width, image.height);
    // }

    final imageSaverService =
        QuillSharedExtensionsConfigurations.get(context: context)
            .imageSaverService;
    return GestureDetector(
      onTap: configurations.onImageClicked ??
          () => showDialog(
                context: context,
                builder: (_) {
                  if (flutterQuillUtilsArgs.elementSize != null) {
                    return QuillProvider.value(
                      value: context.requireQuillProvider,
                      child: FlutterQuillLocalizationsWidget(
                        child: ImageOptionsMenu(
                          controller: controller,
                          configurations: configurations,
                          imageSource: imageSource,
                          imageSize: flutterQuillUtilsArgs.elementSize!,
                          isReadOnly: readOnly,
                          imageSaverService: imageSaverService,
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
      child: Builder(
        builder: (context) {
          if (flutterQuillUtilsArgs.margin != null) {
            return Padding(
              padding: EdgeInsets.all(flutterQuillUtilsArgs.margin!),
              child: image,
            );
          }
          return image;
        },
      ),
    );
  }
}
