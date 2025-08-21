import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';

class Message {
  final List<String> text;
  final bool flash;
  final bool marquee;
  final Speed speed;
  final Mode mode;
  final int? animationIndex; // 👈 NEW

  Message({
    required this.text,
    this.flash = false,
    this.marquee = false,
    this.speed = Speed.one,
    this.mode = Mode.left,
    this.animationIndex, // 👈 NEW
  });

  // Convert Message object to JSON
  Map<String, dynamic> toJson() => {
        'text': text,
        'flash': flash,
        'marquee': marquee,
        'speed': speed.hexValue,
        'mode': mode.hexValue,
        if (animationIndex != null) 'animationIndex': animationIndex, // 👈 NEW
      };

  // Convert JSON to Message object
  factory Message.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('text')) {
      throw Exception('Invalid JSON: Message missing "text" key');
    }

    if (!json.containsKey('speed')) {
      throw Exception('Invalid JSON: Message missing "speed" key');
    }

    if (!json.containsKey('mode')) {
      throw Exception('Invalid JSON: Message missing "mode" key');
    }

    if (json['text'] is! List) {
      throw Exception('Invalid JSON: "text" must be a list');
    }

    final textList = json['text'] as List;
    if (textList.any((element) => element == null)) {
      throw Exception('Invalid JSON: "text" list cannot contain null elements');
    }

    return Message(
      text: List<String>.from(textList),
      flash: (json['flash'] as bool?) ?? false,
      marquee: (json['marquee'] as bool?) ?? false,
      speed: Speed.fromHex(json['speed'] as String),
      mode: Mode.fromHex(json['mode'] as String),
      animationIndex: json['animationIndex'] as int?, // 👈 NEW
    );
  }
}
