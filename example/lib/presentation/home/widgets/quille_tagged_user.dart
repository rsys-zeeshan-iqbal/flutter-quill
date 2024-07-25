// ignore_for_file: must_be_immutable, avoid_print

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:intl/intl.dart' as intl;


class QuillEditorPage extends StatefulWidget {
  static const route = "/quillEditorPage";
  List<Map<String, dynamic>> taggedUserList = [];

  QuillEditorPage({
    super.key,
    this.taggedUserList = const [],
  });
  @override
  State<QuillEditorPage> createState() => _QuillEditorPageState();
}

class _QuillEditorPageState extends State<QuillEditorPage> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditorLTR = true;
  String? _taggingCharector = '#';
  OverlayEntry? _hashTagOverlayEntry;
  int? lastHashTagIndex = -1;
  BuildContext? _mainContext;

  ValueNotifier<List<Map<String, dynamic>>> atMentionSearchList =
      ValueNotifier([]);

  late final List<Map<String, dynamic>> _tempAtMentionList =
      widget.taggedUserList;

  @override
  void initState() {
    super.initState();
    _loadFromAssets();
  }

  void _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      // final result = await rootBundle.loadString('assets/sample_data.json');
      // final doc = Document.fromJson(jsonDecode(result));
      final doc = Document()..insert(0, 'Enter your data');
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    } catch (error) {
      final doc = Document()..insert(0, 'Empty asset');
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    }
    _controller!.addListener(editorListener);
    _focusNode.addListener(_advanceTextFocusListener);
  }

  void editorListener() {
    try {
      final index = _controller!.selection.baseOffset;
      var value = _controller!.plainTextEditingValue.text;
      if (value.trim().isNotEmpty) {
        var newString = value.substring(index - 1, index);

        /// check text directionality
        if (newString != ' ' && newString != '\n') {
          _checkEditorTextDirection(newString);
        }
        if (newString == '\n') {
          _isEditorLTR = true;
        }

        if (newString == '#') {
          _taggingCharector = '#';
          if (_hashTagOverlayEntry == null &&
              !(_hashTagOverlayEntry?.mounted ?? false)) {
            lastHashTagIndex = _controller!.selection.baseOffset;
            _hashTagOverlayEntry = _createHashTagOverlayEntry();
            Overlay.of(_mainContext!)!.insert(_hashTagOverlayEntry!);
          }
        }

        if (newString == '@') {
          _taggingCharector = '@';
          if (_hashTagOverlayEntry == null &&
              !(_hashTagOverlayEntry?.mounted ?? false)) {
            lastHashTagIndex = _controller!.selection.baseOffset;
            _hashTagOverlayEntry = _createHashTagOverlayEntry();
            Overlay.of(_mainContext!)!.insert(_hashTagOverlayEntry!);
          }
        }

        /// Add #tag without selecting from suggestion
        if ((newString == ' ' || newString == '\n') &&
            _hashTagOverlayEntry != null &&
            _hashTagOverlayEntry!.mounted) {
          _removeOverLay();
          if (lastHashTagIndex != -1 && index > lastHashTagIndex!) {
            var newWord = value.substring(lastHashTagIndex!, index);
            _onTapOverLaySuggestionItem(newWord.trim());
          }
        }

        /// Show overlay when #tag detect and filter it's list
        if (lastHashTagIndex != -1 &&
            _hashTagOverlayEntry != null &&
            (_hashTagOverlayEntry?.mounted ?? false)) {
          var newWord = value
              .substring(lastHashTagIndex!, value.length)
              .replaceAll('\n', '');

          if (_taggingCharector == '@') {
            _getAtMentionSearchList(newWord.toLowerCase());
          }
        }
      }
    } catch (e) {
      print('Exception in catching last charector : $e');
    }
  }

  void _checkEditorTextDirection(String text) {
    try {
      var _isRTL = intl.Bidi.detectRtlDirectionality(text);
      var style = _controller!.getSelectionStyle();
      var attribute = style.attributes[Attribute.align.key];
      // print(attribute);
      if (_isEditorLTR) {
        if (_isEditorLTR != !_isRTL) {
          if (_isRTL) {
            _isEditorLTR = false;
            _controller!
                .formatSelection(Attribute.clone(Attribute.align, null));
            _controller!.formatSelection(Attribute.rightAlignment);
            _refreshScreen();
          } else {
            var validCharacters = RegExp(r'^[a-zA-Z]+$');
            if (validCharacters.hasMatch(text)) {
              _isEditorLTR = true;
              _controller!
                  .formatSelection(Attribute.clone(Attribute.align, null));
              _controller!.formatSelection(Attribute.leftAlignment);
              _refreshScreen();
            }
          }
        } else {
          if (attribute == null && _isRTL) {
            _isEditorLTR = false;
            _controller!
                .formatSelection(Attribute.clone(Attribute.align, null));
            _controller!.formatSelection(Attribute.rightAlignment);
            _refreshScreen();
          } else if (attribute == Attribute.rightAlignment && !_isRTL) {
            var validCharacters = RegExp(r'^[a-zA-Z]+$');
            if (validCharacters.hasMatch(text)) {
              _isEditorLTR = true;
              _controller!
                  .formatSelection(Attribute.clone(Attribute.align, null));
              _controller!.formatSelection(Attribute.leftAlignment);
              _refreshScreen();
            }
          }
        }
      }
    } catch (e) {
      print('Exception in _checkEditorTextDirection : $e');
    }
  }

  OverlayEntry _createHashTagOverlayEntry() {
    return OverlayEntry(
        builder: (context) => Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              width: MediaQuery.of(context).size.width,
              // height: 150,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints:
                      const BoxConstraints(maxHeight: 150, minHeight: 50),
                  child: ValueListenableBuilder(
                    valueListenable: atMentionSearchList,
                    builder: (BuildContext context,
                        List<Map<String, dynamic>> value, Widget? child) {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: value.length,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          var data = value[index];
                          return GestureDetector(
                            onTap: () {
                              _onTapOverLaySuggestionItem(data['name'],
                                  userId: data['id']);
                            },
                            child: ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: data['image'] ?? '',
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                      shape: BoxShape.circle),
                                ),
                                placeholder: (context, url) => Container(
                                  height: 30,
                                  width: 30,
                                  decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle),
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              title: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    '@${data['id']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ));
  }

  void _removeOverLay() {
    try {
      if (_hashTagOverlayEntry != null && _hashTagOverlayEntry!.mounted) {
        _hashTagOverlayEntry!.remove();
        _hashTagOverlayEntry = null;

        atMentionSearchList.value = <Map<String, dynamic>>[];
      }
    } catch (e) {
      print('Exception in removing overlay :$e');
    }
  }

  void _onTapOverLaySuggestionItem(String value, {String? userId}) {
    var _lastHashTagIndex = lastHashTagIndex;
    _controller!.replaceText(_lastHashTagIndex!,
        _controller!.selection.extentOffset - _lastHashTagIndex, value, null);
    _controller!.updateSelection(
        TextSelection(
            baseOffset: _lastHashTagIndex - 1,
            extentOffset: _controller!.selection.extentOffset +
                (value.length -
                    (_controller!.selection.extentOffset - _lastHashTagIndex))),
        ChangeSource.LOCAL);
    if (_taggingCharector == '#') {
      /// You can add your own web site
      _controller!.formatSelection(
          LinkAttribute('https://www.google.com/search?q=$value'));
    } else {
      /// You can add your own web site
      _controller!.formatSelection(
          LinkAttribute('https://www.google.com/search?q=$userId'));
    }
    Future.delayed(Duration.zero).then((value) {
      _controller!.moveCursorToEnd();
    });
    lastHashTagIndex = -1;
    _controller!.document.insert(_controller!.selection.extentOffset, ' ');
    Future.delayed(const Duration(seconds: 1))
        .then((value) => _removeOverLay());

    atMentionSearchList.value = <Map<String, dynamic>>[];
  }

  void _advanceTextFocusListener() {
    if (!_focusNode.hasPrimaryFocus) {
      if (_hashTagOverlayEntry != null) {
        if (_hashTagOverlayEntry!.mounted) {
          _removeOverLay();
        }
      }
    }
  }

  Future<void> _getAtMentionSearchList(String? query) async {
    /// you can call api here to get the list
    try {
      atMentionSearchList.value = _tempAtMentionList;
    } catch (e) {
      print('Exception in _getAtMentionSearchList : $e');
    }
  }

  @override
  void dispose() {
    _controller!.removeListener(editorListener);
    _focusNode.removeListener(_advanceTextFocusListener);
    _controller!.dispose();
    if (_hashTagOverlayEntry != null) {
      if (_hashTagOverlayEntry!.mounted) {
        _removeOverLay();
      }
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        _hashTagOverlayEntry!.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _mainContext = context;
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Flutter Quill',
        ),
        actions: [],
      ),
      drawer: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        color: Colors.grey.shade800,
        child: _buildMenuBar(context),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.data.isControlPressed && event.character == 'b') {
            if (_controller!
                .getSelectionStyle()
                .attributes
                .keys
                .contains('bold')) {
              _controller!
                  .formatSelection(Attribute.clone(Attribute.bold, null));
            } else {
              _controller!.formatSelection(Attribute.bold);
            }
          }
        },
        child: _buildWelcomeEditor(context),
      ),
    );
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    var quillEditor = QuillEditor(
      focusNode: _focusNode,
      scrollController: ScrollController(),
      configurations: QuillEditorConfigurations(
          scrollable: true,
          autoFocus: false,
          readOnly: false,
          placeholder: 'Add content',
          expands: false,
          padding:
              EdgeInsets.only(bottom: !_focusNode.hasPrimaryFocus ? 10 : 150),
          scrollBottomInset: 150,
          customStyles: DefaultStyles(
              link: const TextStyle().copyWith(color: Colors.blue),
              paragraph: DefaultTextBlockStyle(
                const TextStyle().copyWith(
                  fontSize: 17,
                  color: const Color(0xFF292929),
                  height: 1.3,
                ),
                VerticalSpacing(0, 0),
                VerticalSpacing(0, 0),
                BoxDecoration(
                  color: Colors.purpleAccent,
                ),
              ))),
    );
    if (kIsWeb) {
      quillEditor = QuillEditor(
        focusNode: _focusNode,
        scrollController: ScrollController(),
        configurations: const QuillEditorConfigurations(
          scrollable: true,
          autoFocus: false,
          readOnly: false,
          placeholder: 'Add content',
          expands: false,
          padding: EdgeInsets.zero,
          customStyles: DefaultStyles(
            h1: DefaultTextBlockStyle(
              TextStyle(
                fontSize: 32,
                color: Colors.black,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              VerticalSpacing(0, 0),
              VerticalSpacing(0, 0),
              BoxDecoration(
                color: Colors.purpleAccent,
              ),
            ),
          ),
        ),
      );
    }
    var toolbar = const QuillToolbar(
      configurations: QuillToolbarConfigurations(
        // provide a callback to enable picking images from device.
        // if omit, "image" button only allows adding images from url.
        // same goes for videos.

        // uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _selectMediaPickSetting,
        showAlignmentButtons: true,
        multiRowsDisplay: false,
      ),
    );

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: quillEditor,
            ),
          ),
          kIsWeb
              ? Expanded(
                  child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: toolbar,
                ))
              : Container(child: toolbar)
        ],
      ),
    );
  }

  Widget _buildMenuBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const itemStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Divider(
          thickness: 2,
          color: Colors.white,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
        Divider(
          thickness: 2,
          color: Colors.white,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
      ],
    );
  }
}
