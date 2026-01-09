import 'brightness.dart';
import 'messages.dart';

class Data {
  final List<Message> messages;
  final Brightness brightness;
  
  Data({
    required this.messages,
    this.brightness = Brightness.hundred,
  });

  // Convert Data object to JSON
  Map<String, dynamic> toJson() => {
        'messages': messages.map((message) => message.toJson()).toList(),
        'brightness': brightness.hexValue,
      };

  // Convert JSON to Data object
  factory Data.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('messages')) {
      throw Exception('Invalid JSON: Missing "messages" key');
    }

    if (json['messages'] is! List) {
      throw Exception('Invalid JSON: "messages" must be a list');
    }

    if (json['messages'].isEmpty) {
      throw Exception('Invalid JSON: "messages" list is empty');
    }

    var messagesFromJson = json['messages'] as List;

    if (messagesFromJson.any((message) => message == null)) {
      throw Exception('Invalid JSON: "messages" list contains null values');
    }

    List<Message> messageList =
        messagesFromJson.map((message) => Message.fromJson(message)).toList();

    final raw = json['brightness'];
    final brightness = raw is String && raw.isNotEmpty
        ? Brightness.fromHex(raw)
        : Brightness.hundred;

    return Data(
      messages: messageList,
      brightness: brightness,
    );
  }
}
