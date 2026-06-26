import 'messages.dart';

class Data {
  final List<Message> messages;
  String? originalText;
  Map<String, List<List<int>>>? customCliparts;

  Data({
    required this.messages,
    this.originalText,
    this.customCliparts,
  });

  // Convert Data object to JSON
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'messages': messages.map((message) => message.toJson()).toList(),
    };
    if (originalText != null) {
      data['originalText'] = originalText;
    }
    if (customCliparts != null && customCliparts!.isNotEmpty) {
      data['customCliparts'] = customCliparts;
    }
    return data;
  }

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

    String? originalText = json['originalText'] as String?;

    Map<String, List<List<int>>>? customCliparts;
    if (json.containsKey('customCliparts') && json['customCliparts'] != null) {
      customCliparts = {};
      final map = json['customCliparts'] as Map<String, dynamic>;
      map.forEach((key, value) {
        if (value is List) {
          customCliparts![key] = value.map((row) {
            return List<int>.from(row as List);
          }).toList();
        }
      });
    }

    return Data(
      messages: messageList,
      originalText: originalText,
      customCliparts: customCliparts,
    );
  }
}
