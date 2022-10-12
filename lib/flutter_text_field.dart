// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class RichTextEditingValue {
  final String text;
  final String data;
  final TextRange selection;
  final String inputText;

  const RichTextEditingValue({
    this.text = '',
    this.data = '',
    this.inputText = '',
    this.selection = const TextRange.collapsed(0),
  });

  static const RichTextEditingValue empty = RichTextEditingValue();

  RichTextEditingValue copyWith({
    String? text,
    String? data,
    String? inputText,
    TextRange? selection,
  }) {
    return RichTextEditingValue(
      text: text ?? this.text,
      data: data ?? this.data,
      inputText: inputText ?? '',
      selection: selection ?? this.selection,
    );
  }

  static RichTextEditingValue fromJSON(Map? encoded) {
    if (encoded == null) return RichTextEditingValue.empty;
    return RichTextEditingValue(
      text: encoded['text'],
      data: encoded['data'],
      selection: TextRange(
        start: encoded['selection_start'] as int,
        end: encoded['selection_end'] as int,
      ),
      inputText: encoded['input_text'],
    );
  }
}

class RichTextFieldController extends ValueNotifier<RichTextEditingValue> {
  MethodChannel? _channel;
  TextStyle? _defaultRichTextStyle;
  String? _viewId;

  String get text => value.text;

  set text(String? newText) {
    setText(newText);
    value = value.copyWith(
      text: newText,
      selection: const TextSelection.collapsed(offset: -1),
    );
  }

  String get data => value.data;

  RichTextFieldController({TextStyle? defaultRichTextStyle})
      : super(RichTextEditingValue.empty) {
    _defaultRichTextStyle = defaultRichTextStyle ??
        TextStyle(color: Colors.lightBlueAccent, fontSize: 14, height: 1.17);
  }

  Future wait(Function func) async {
    for (int i = 0; i < 5; i++) {
      if (_channel != null) {
        return func.call();
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return Future.value();
  }

  Future setPlaceholder(String placeholder) {
    return wait(() => _channel?.invokeMethod("setPlaceholder", placeholder));
  }

  void setViewId(String viewId) {
    if (_channel == null || _viewId != viewId) {
      _viewId = viewId;
      _channel = MethodChannel('com.fanbook.rich_textfield_$viewId');
    }
  }

  void setMethodCallHandler(
      Future<dynamic> Function(MethodCall call)? handler) {
    _channel?.setMethodCallHandler(handler);
  }

  Future insertText(String text, {int backSpaceLength = 0}) async {
    return wait(() => _channel?.invokeMethod("insertText", {
          'text': text,
          'backSpaceLength': backSpaceLength,
        }));
  }

  Future updateWidth(double width) async {
    return wait(() => _channel?.invokeMethod("updateWidth", width));
  }

  Future insertAtName(String name,
      {String data = '', TextStyle? textStyle, int backSpaceLength = 0}) async {
    return wait(() => insertBlock('$name ',
        data: data,
        textStyle: textStyle,
        prefix: '@',
        backSpaceLength: backSpaceLength));
  }

  Future insertChannelName(String name,
      {String data = '', TextStyle? textStyle, int backSpaceLength = 0}) async {
    return wait(() => insertBlock('$name ',
        data: data,
        textStyle: textStyle,
        prefix: '#',
        backSpaceLength: backSpaceLength));
  }

  Future insertBlock(String name,
      {String data = '',
      TextStyle? textStyle,
      String prefix = '',
      int backSpaceLength = 0}) {
    textStyle ??= _defaultRichTextStyle;
    return wait(() => _channel?.invokeMethod("insertBlock", {
          'name': name,
          'data': data,
          'prefix': prefix,
          'backSpaceLength': backSpaceLength,
          'textStyle': {
            'color': textStyle!.color!.value,
            'fontSize': textStyle.fontSize,
            'height': textStyle.height ?? 1.17
          }
        }));
  }

  Future updateFocus(bool focus) async {
    return wait(() => _channel?.invokeMethod("updateFocus", focus));
  }

  Future replace(String text, TextRange range) async {
    return wait(() => _channel?.invokeMethod("replace", {
          'text': text,
          'selection_start': range.start,
          'selection_end': range.end,
        }));
  }

  Future setAlpha(double alpha) async {
    return wait(() => _channel!.invokeMethod("setAlpha", alpha));
  }

  Future replaceAll(String text) async {
    return setText(text);
  }

  Future clear() async {
    return setText('');
  }

  Future setText(String? text) async {
    return wait(() => _channel?.invokeMethod("setText", text));
  }

  @override
  set value(RichTextEditingValue newValue) {
    super.value = newValue;
  }
}

class RichTextField extends StatefulWidget {
  final RichTextFieldController controller;
  final FocusNode focusNode;
  final String text;
  final TextStyle? textStyle;
  final String placeHolder;
  final TextStyle? placeHolderStyle;
  final int maxLength;
  final double? width;
  final double? height;
  final double maxHeight;
  final double minHeight;
  final EdgeInsets textContainerInset;
  final VoidCallback? onEditingComplete;
  final Function(String)? onSubmitted;
  final Function(String?)? onChanged;
  final Function(double)? cursorPositionChanged;
  final bool autoFocus;
  final bool needEagerGesture;
  final VoidCallback? scrollFromBottomTop;
  final Color? cursorColor;
  final bool placeHolderBreakWord;
  final bool useHybridComposition;

  const RichTextField({
    required this.controller,
    required this.focusNode,
    this.text = '',
    this.textStyle,
    this.placeHolder = '',
    this.placeHolderStyle,
    this.maxLength = 5000,
    this.width,
    this.height,
    this.maxHeight = 142,
    this.minHeight = 32,
    this.textContainerInset = const EdgeInsets.fromLTRB(10, 8, 0, 4),
    this.onEditingComplete,
    this.onSubmitted,
    this.cursorPositionChanged,
    this.onChanged,
    this.autoFocus = false,
    this.needEagerGesture = true,
    this.scrollFromBottomTop,
    this.placeHolderBreakWord = false,
    this.useHybridComposition = true,
    this.cursorColor,
  });

  @override
  _RichTextFieldState createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  double? _height = 40;
  bool? _backFoucus;
  int _time = DateTime.now().millisecondsSinceEpoch;

  Map createParams() {
    return {
      'width': widget.width ?? MediaQuery.of(context).size.width,
      'height': widget.height,
      'maxHeight': widget.maxHeight,
      'minHeight': widget.minHeight,
      'text': widget.text,
      'textStyle': {
        'color': widget.textStyle!.color!.value,
        'fontSize': widget.textStyle!.fontSize,
        'height': widget.textStyle!.height ?? 1.17
      },
      'placeHolder': widget.placeHolder,
      'placeHolderStyle': {
        'color': widget.placeHolderStyle!.color!.value,
        'fontSize': widget.placeHolderStyle!.fontSize,
        'height': widget.placeHolderStyle!.height ?? 1.35
      },
      'maxLength': widget.maxLength,
      'done': widget.onEditingComplete != null || widget.onSubmitted != null,
      'cursorColor': (widget.cursorColor ?? Colors.black).value,
      'textContainerInset': {
        'left': widget.textContainerInset.left,
        'top': widget.textContainerInset.top,
        'right': widget.textContainerInset.right,
        'bottom': widget.textContainerInset.bottom
      },
      'placeHolderBreakWord': widget.placeHolderBreakWord,
    };
  }

  Future<void> _handlerCall(MethodCall call) async {
    switch (call.method) {
      case 'updateHeight':
        setState(() {
          _height = call.arguments ?? 40;
        });
        break;
      case 'updateFocus':
        final focus = call.arguments ?? false;
        _backFoucus = focus;
        if (focus) {
          widget.focusNode.requestFocus();
        } else {
          widget.focusNode.unfocus();
        }
        break;
      case 'updateValue':
        final Map? temp = call.arguments;
        final value = RichTextEditingValue.fromJSON(temp);
        widget.controller.value = value;
        widget.onChanged?.call(value.text);
        break;
      case 'submitText':
        final text = call.arguments ?? '';
        widget.onSubmitted?.call(text);
        widget.onEditingComplete?.call();
        break;
      case 'updateCursor':
        final position = call.arguments ?? 0;
        widget.cursorPositionChanged?.call(position);
        break;
      case 'hideKeyboard':
        widget.scrollFromBottomTop?.call();
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    if (widget.height != null) _height = widget.height;
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.setMethodCallHandler(null);
    super.dispose();
  }

  void onFocusChange(bool focus) {
    // 从原生回调的foucs，不再传回原生
    if (_backFoucus == focus) {
      _backFoucus = null;
      return;
    }
    // 防抖处理
    final time = DateTime.now().millisecondsSinceEpoch;
    if (time > _time + 200) {
      _time = time;
      widget.controller.updateFocus(focus);
    }
    // 清理
    if (_backFoucus != null) _backFoucus = null;
  }

  @override
  Widget build(BuildContext context) {
    final gestureRecognizers = widget.needEagerGesture
        ? <Factory<OneSequenceGestureRecognizer>>[
            new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer(),
            ),
          ].toSet()
        : null;
    final height = _height! > widget.maxHeight ? widget.maxHeight : _height;
    if (Platform.isIOS) {
      return SizedBox(
        height: height,
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: onFocusChange,
          child: UiKitView(
            viewType: "com.fanbook.rich_textfield",
            creationParams: createParams(),
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: (viewId) {
              widget.controller.setViewId('$viewId');
              widget.controller.setMethodCallHandler(_handlerCall);
              if (widget.autoFocus) widget.controller.updateFocus(true);
            },
            gestureRecognizers: gestureRecognizers,
          ),
        ),
      );
    } else if (Platform.isAndroid) {
      return SizedBox(
        height: height,
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: onFocusChange,
          child: widget.useHybridComposition
              ? PlatformViewLink(
                  viewType: "com.fanbook.rich_textfield",
                  surfaceFactory: (context, controller) {
                    return AndroidViewSurface(
                      controller: controller as AndroidViewController,
                      gestureRecognizers: gestureRecognizers!,
                      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    );
                  },
                  onCreatePlatformView: (params) {
                    params.onPlatformViewCreated(params.id);
                    return PlatformViewsService.initSurfaceAndroidView(
                      id: params.id,
                      viewType: "com.fanbook.rich_textfield",
                      layoutDirection: TextDirection.ltr,
                      creationParams: createParams(),
                      creationParamsCodec: const StandardMessageCodec(),
                    )
                      ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
                      ..create();
                  },
                )
              : AndroidView(
                  viewType: 'com.fanbook.rich_textfield',
                  layoutDirection: TextDirection.ltr,
                  creationParams: createParams(),
                  creationParamsCodec: const StandardMessageCodec(),
                  onPlatformViewCreated: _onPlatformViewCreated,
                ),
        ),
      );
    } else {
      return Text('暂不支持该平台');
    }
  }

  void _onPlatformViewCreated(int id) {
    widget.controller.setViewId('$id');
    widget.controller.setMethodCallHandler(_handlerCall);
    if (widget.autoFocus) widget.controller.updateFocus(true);
  }
}
