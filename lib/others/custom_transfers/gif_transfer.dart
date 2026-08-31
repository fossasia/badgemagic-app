import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';
import 'package:logger/logger.dart';

Future<void> customTransferGifAnimation(
    Future<void> Function(DataTransferManager) transferData,
    List<List<List<bool>>> frames,
    int speedLevel) async {
  if (!await checkAdapterState()) return;

  const int maxFrames = 8;
  final Speed selectedSpeed = Speed.values[(speedLevel - 1).clamp(0, 7)];
  final logger = Logger();

  final List<List<List<bool>>> sampledFrames;
  if (frames.length <= maxFrames) {
    sampledFrames = frames;
  } else {
    sampledFrames = List.generate(
        maxFrames, (i) => frames[(i * frames.length / maxFrames).floor()]);
  }

  logger
      .i('Starting GIF animation transfer (${sampledFrames.length} frames)...');

  final List<Message> messages = [];
  for (final frame in sampledFrames) {
    final List<List<int>> intBitmap = boolToIntBitmap(frame);
    final List<String> hexList =
        Converters.convertBitmapToLEDHex(intBitmap, false);
    messages.add(Message(
      text: hexList,
      mode: Mode.fixed,
      speed: selectedSpeed,
      flash: false,
      marquee: false,
    ));
  }

  final Data data = Data(messages: messages);
  final DataTransferManager manager = DataTransferManager(data);
  await transferData(manager);
  logger.i('💡 GIF animation transfer completed successfully!');
}
