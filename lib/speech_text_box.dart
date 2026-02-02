import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


class SpeechToTextWidget extends StatefulWidget {
  InputDecoration? _decoration;
  TextStyle? _style;
  TextEditingController? _controller;

  SpeechToTextWidget({
    super.key,
    //String? initialValue,
    //InputDecoration? decoration,
    //TextInputType? keyboardType,
    //TextStyle? style,
    TextEditingController? controller,
  }) {
    _controller = controller;
  }

  late _SpeechToTextWidget _state;

  @override
  _SpeechToTextWidget createState () {
    _state = _SpeechToTextWidget (_controller);

   // _state._text_decoration = _decoration;
    //_state._text_style = _style;

    return _state;
  }

  String GetText () {
    return _state._text_controller.text;
  }

  void SetText (String? value) {
    if (value != null) {
      _state._text_controller.text = value;
    } else {
      _state._text_controller.clear ();
    }
  }
}

class _SpeechToTextWidget extends State <SpeechToTextWidget> {
  late TextEditingController _text_controller;
  final SpeechToText _speech_to_text = SpeechToText ();
  bool _speechEnabled = false;
  //String _content = "";
  //InputDecoration? _text_decoration;
  //TextStyle? _text_style;


  _SpeechToTextWidget (TextEditingController? controller) {
    if (controller != null) {
      _text_controller = controller;
    } else {
      _text_controller = TextEditingController ();
    }
  }


  void listenForPermissions () async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
        break;
      case PermissionStatus.limited:
        break;
      case PermissionStatus.permanentlyDenied:
        break;
      case PermissionStatus.provisional:
        break;
      case PermissionStatus.restricted:
        break;
    }
  }

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }

  @override
  void initState() {
    super.initState();
    listenForPermissions();
    if (!_speechEnabled) {
      _initSpeech();
    }
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speech_to_text.initialize();
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speech_to_text.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      localeId: "en_En",
      cancelOnError: false,
      partialResults: false,
      listenMode: ListenMode.confirmation,
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speech_to_text.stop ();
    setState (() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult (SpeechRecognitionResult result) {
    setState(() {
      String old_content = _text_controller.text;
      String new_content = "${old_content}${result.recognizedWords} ";
      _text_controller.text = new_content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row (
      children: <Widget> [
        Expanded (
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _text_controller,
                  minLines: 6,
                  maxLines: 10,
                  //decoration: _text_decoration,
                  decoration: InputDecoration(labelText: "Notes (Optional)"),
                  //style: _text_style,
                  keyboardType: TextInputType.text,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              FloatingActionButton.small(
                onPressed:
                // If not yet listening for speech start, otherwise stop
                _speech_to_text.isNotListening
                    ? _startListening
                    : _stopListening,
                tooltip: 'Listen',
                backgroundColor: Colors.blueGrey,
                child: Icon (_speech_to_text.isNotListening
                    ? Icons.mic_off
                    : Icons.mic),
              )
            ],
          ),

        ),
      ],
    );

  }
}