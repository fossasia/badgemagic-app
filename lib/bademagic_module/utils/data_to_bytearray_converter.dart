import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:logger/logger.dart';

class DataToByteArrayConverter {
  final Logger logger = Logger();

  var maxMessages = 8;
  var packetStart = "77616E670000";
  var packetByteSize = 16;

  final Map<String, String> charCodes = {
    '0': "007CC6CEDEF6E6C6C67C00",
    '1': "0018387818181818187E00",
    '2': "007CC6060C183060C6FE00",
    '3': "007CC606063C0606C67C00",
    '4': "000C1C3C6CCCFE0C0C1E00",
    '5': "00FEC0C0FC060606C67C00",
    '6': "007CC6C0C0FCC6C6C67C00",
    '7': "00FEC6060C183030303000",
    '8': "007CC6C6C67CC6C6C67C00",
    '9': "007CC6C6C67E0606C67C00",
    '#': "006C6CFE6C6CFE6C6C0000",
    '&': "00386C6C3876DCCCCC7600",
    '_': "00000000000000000000FF",
    '-': "0000000000FE0000000000",
    '?': "007CC6C60C181800181800",
    '@': "00003C429DA5ADB6403C00",
    '(': "000C183030303030180C00",
    ')': "0030180C0C0C0C0C183000",
    '=': "0000007E00007E00000000",
    '+': "00000018187E1818000000",
    '!': "00183C3C3C181800181800",
    '\'': "1818081000000000000000",
    ':': "0000001818000018180000",
    '%': "006092966C106CD2920C00",
    '/': "000002060C183060C08000",
    '"': "6666222200000000000000",
    '[': "003C303030303030303C00",
    ']': "003C0C0C0C0C0C0C0C3C00",
    ' ': "0000000000000000000000",
    '*': "000000663CFF3C66000000",
    ',': "0000000000000030301020",
    '.': "0000000000000000303000",
    '\$': "107CD6D6701CD6D67C1010",
    '~': "0076DC0000000000000000",
    '{': "000E181818701818180E00",
    '}': "00701818180E1818187000",
    '<': "00060C18306030180C0600",
    '>': "006030180C060C18306000",
    '^': "386CC60000000000000000",
    '`': "1818100800000000000000",
    ';': "0000001818000018180810",
    '\\': "0080C06030180C06020000",
    '|': "0018181818001818181800",
    'a': "00000000780C7CCCCC7600",
    'b': "00E060607C666666667C00",
    'c': "000000007CC6C0C0C67C00",
    'd': "001C0C0C7CCCCCCCCC7600",
    'e': "000000007CC6FEC0C67C00",
    'f': "001C363078303030307800",
    'g': "00000076CCCCCC7C0CCC78",
    'h': "00E060606C76666666E600",
    'i': "0018180038181818183C00",
    'j': "0C0C001C0C0C0C0CCCCC78",
    'k': "00E06060666C78786CE600",
    'l': "0038181818181818183C00",
    'm': "00000000ECFED6D6D6C600",
    'n': "00000000DC666666666600",
    'o': "000000007CC6C6C6C67C00",
    'p': "000000DC6666667C6060F0",
    'q': "0000007CCCCCCC7C0C0C1E",
    'r': "00000000DE76606060F000",
    's': "000000007CC6701CC67C00",
    't': "00103030FC303030341800",
    'u': "00000000CCCCCCCCCC7600",
    'v': "00000000C6C6C66C381000",
    'w': "00000000C6D6D6D6FE6C00",
    'x': "00000000C66C38386CC600",
    'y': "000000C6C6C6C67E060CF8",
    'z': "00000000FE8C183062FE00",
    'A': "00386CC6C6FEC6C6C6C600",
    'B': "00FC6666667C666666FC00",
    'C': "007CC6C6C0C0C0C6C67C00",
    'D': "00FC66666666666666FC00",
    'E': "00FE66626878686266FE00",
    'F': "00FE66626878686060F000",
    'G': "007CC6C6C0C0CEC6C67E00",
    'H': "00C6C6C6C6FEC6C6C6C600",
    'I': "003C181818181818183C00",
    'J': "001E0C0C0C0C0CCCCC7800",
    'K': "00E6666C6C786C6C66E600",
    'L': "00F060606060606266FE00",
    'M': "0082C6EEFED6C6C6C6C600",
    'N': "0086C6E6F6DECEC6C6C600",
    'O': "007CC6C6C6C6C6C6C67C00",
    'P': "00FC6666667C606060F000",
    'Q': "007CC6C6C6C6C6D6DE7C06",
    'R': "00FC6666667C6C6666E600",
    'S': "007CC6C660380CC6C67C00",
    'T': "007E7E5A18181818183C00",
    'U': "00C6C6C6C6C6C6C6C67C00",
    'V': "00C6C6C6C6C6C66C381000",
    'W': "00C6C6C6C6D6FEEEC68200",
    'X': "00C6C66C7C387C6CC6C600",
    'Y': "00666666663C1818183C00",
    'Z': "00FEC6860C183062C6FE00",
    'Á': "0810386cc6c6fec6c6c600",
    'À': "2010386cc6c6fec6c6c600",
    'Â': "1028386CC6C6FEC6C6C600",
    'Ä': "2800386CC6C6FEC6C6C600",
    'Å': "1028107CC6C6FEC6C6C600",
    'É': "0810FE626878686266FE00",
    'È': "2010FE626878686266FE00",
    'Ê': "1028FE626878686266FE00",
    'Ë': "2800FE626878686266FE00",
    'Ě': "2810FE626878686266FE00",
    'Í': "04083C1818181818183C00",
    'Ì': "10083C1818181818183C00",
    'Î': "08143C1818181818183C00",
    'Ï': "14003C1818181818183C00",
    'Ó': "08107CC6C6C6C6C6C67C00",
    'Ò': "20107CC6C6C6C6C6C67C00",
    'Ô': "10287CC6C6C6C6C6C67C00",
    'Ö': "28007CC6C6C6C6C6C67C00",
    'Ő': "14287CC6C6C6C6C6C67C00",
    'Ú': "0810C6C6C6C6C6C6C67C00",
    'Ù': "2010C6C6C6C6C6C6C67C00",
    'Û': "1028C6C6C6C6C6C6C67C00",
    'Ü': "2800C6C6C6C6C6C6C67C00",
    'Ű': "1428C6C6C6C6C6C6C67C00",
    'Ů': "102810C6C6C6C6C6C67C00",
    'Ý': "04086666663C1818183C00",
    'Ÿ': "14006666663C1818183C00",
    'á': "00000810780C7CCCCC7600",
    'à': "00002010780C7CCCCC7600",
    'â': "00102800780C7CCCCC7600",
    'ä': "00002800780C7CCCCC7600",
    'å': "00102810780C7CCCCC7600",
    'é': "000008107CC6FEC0C67C00",
    'è': "000020107CC6FEC0C67C00",
    'ê': "001028007CC6FEC0C67C00",
    'ë': "000028007CC6FEC0C67C00",
    'ě': "000028107CC6FEC0C67C00",
    'í': "0000081038181818183C00",
    'ì': "0000201038181818183C00",
    'î': "0008140038181818183C00",
    'ï': "0000140038181818183C00",
    'ó': "000008107CC6C6C6C67C00",
    'ò': "000020107CC6C6C6C67C00",
    'ô': "001028007CC6C6C6C67C00",
    'ö': "000028007CC6C6C6C67C00",
    'ő': "000014287CC6C6C6C67C00",
    'ú': "00000810CCCCCCCCCC7600",
    'ù': "00002010CCCCCCCCCC7600",
    'û': "00102800CCCCCCCCCC7600",
    'ü': "00002800CCCCCCCCCC7600",
    'ű': "00001428CCCCCCCCCC7600",
    'ů': "00102810CCCCCCCCCC7600",
    'ý': "000810C6C6C6C67E060CF8",
    'ÿ': "002800C6C6C6C67E060CF8",
    'Ç': "007CC6C6C0C0C0C67C1030",
    'ç': "000000007CC6C0467C1030",
    'Ñ': "342CC6E6F6DECEC6C6C600",
    'ñ': "00342C00DC666666666600",
    'Č': "28107CC6C6C0C0C6C67C00",
    'č': "000028107CC6C0C0C67C00",
    'Ď': "2810FC666666666666FC00",
    'ď': "02061C0C7CCCCCCCCC7600",
    'Ň': "2810C6E6F6DECEC6C6C600",
    'ň': "00002810DC666666666600",
    'Ř': "2810FC66667C6C6666E600",
    'ř': "00002810DE76606060F000",
    'Š': "28107CC6E0380CC6C67C00",
    'š': "000028107CC6701CC67C00",
    'Ť': "14087E7E5A181818183C00",
    'ť': "00143430FC303030341800",
    'Ž': "2810FE860C183062C6FE00",
    'ž': "00002810FE8C183062FE00"
  };

//This function is used to add all the chunks of message that have been calculates
//and converts them into an array of byte characters
//this array of byte characters are stored in List<int>
//this message is chunked into 32 bytes of each
//and each 32 bytes of the mesasge is then transmitted to the hexString to byte
//array function which generates a list of bytes to pass
  List<List<int>> convert(Data data) {
    assert(data.messages.length <= maxMessages, "Max messages=$maxMessages");

    String message =
        ("$packetStart${getFlash(data)}${getMarquee(data)}${getOptions(data)}${getSizes(data)}000000000000${getTime(DateTime.now())}0000000000000000000000000000000000000000${getMessage(data)}");
    int length = message.length;
    message += fillZeros(length);
    logger.d("Final Message is = $message");
    List<String> chunks = [];
    int chunkSize = packetByteSize * 2;
    for (var i = 0; i < message.length; i += chunkSize) {
      int end =
          (i + chunkSize) < message.length ? i + chunkSize : message.length;
      chunks.add(message.substring(i, end));
    }
    List<List<int>> ans = [];
    for (int x = 0; x < chunks.length; x++) {
      ans.add(hexStringToByteArray(chunks[x]));
    }
    return ans;
  }

//Function to get flash bytes of the message
  String getFlash(Data data) {
    List<int> flashByte = List<int>.filled(1, 0);

    data.messages.asMap().forEach((index, message) {
      int flashFlag = message.flash ? 1 : 0;
      flashByte[0] = flashByte[0] | (flashFlag << index) & 0xFF;
    });
    logger.d("Get flash = ${toHex(flashByte)}");
    return toHex(flashByte);
  }

//Function to get the Marquee bytes of the message
  String getMarquee(Data data) {
    List<int> marqueeBytes = List<int>.filled(1, 0);
    data.messages.asMap().forEach((index, message) {
      int marqueeFlag = message.marquee ? 1 : 0;
      marqueeBytes[0] = marqueeBytes[0] | (marqueeFlag << index) & 0xFF;
    });
    logger.d("Get Marquee = ${toHex(marqueeBytes)}");
    return toHex(marqueeBytes);
  }

//gets the values of the mode and speed from the message and takes
//or operation on them and then converts them to hexadecimal value
  String getOptions(Data data) {
    final nbMessages = data.messages.length;
    String ans = data.messages
            .map((message) =>
                int.parse(message.speed.hexValue) |
                int.parse(message.mode.hexValue))
            .map((value) => toHex(List<int>.filled(1, value)))
            .join() +
        '00' * (maxMessages - nbMessages);
    logger.d("get options = $ans");
    return ans;
  }

  String getSizes(Data data) {
    final nbMessages = data.messages.length;
    String ans = data.messages
        .map((m) => m.text.length)
        .map((length) => toHex([
              // Specify radix 16 for hexadecimal parsing
              int.parse(
                  ((length >> 8) & 0xFF).toRadixString(16).padLeft(2, '0'),
                  radix: 16),
              int.parse((length & 0xFF).toRadixString(16).padLeft(2, '0'),
                  radix: 16),
            ]))
        .join()
        .padRight(32 - nbMessages * 4 + 4, '0');
    logger.d("get sizes = $ans");
    return ans;
  }

//Function converts the date time of the call to hexvalue
  String getTime(DateTime now) {
    String ans = toHex([
      int.parse((now.year & 0xFF).toString().padLeft(2, '0')),
      int.parse(((now.month + 1) & 0xFF).toString().padLeft(2, '0')),
      int.parse((now.day & 0xFF).toString().padLeft(2, '0')),
      int.parse((now.hour & 0xFF).toString().padLeft(2, '0')),
      int.parse((now.minute & 0xFF).toString().padLeft(2, '0')),
      int.parse((now.second & 0xFF).toString().padLeft(2, '0'))
    ]);
    logger.d("get time = $ans");
    return ans;
  }

//takes the list of hexstrings generated by the message to hex function
//and converts them to a single string
//ignoring the [] due  to the list object using regexp
//and returns a single string
  String getMessage(Data data) {
    String ans = data.messages
        .map((message) =>
            message.text.join('').replaceAll(RegExp(r'^\[|\]$'), ''))
        .join('');
    logger.d("Get message = $ans");
    return ans;
  }

//filling he rest length with the 0
  String fillZeros(int length) {
    String ans = "0" *
        ((((length / (16 * 2)) + 1).floor() * 16 * 2).floor() - length).toInt();
    logger.d("Fill with zeroes = $ans no of zeroes = ${ans.length}");
    return ans;
  }
}
