import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:get_it/get_it.dart';

class DataTransferManager {
  final Data data;
  //make it singleton

  DataTransferManager(this.data);

  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  DataToByteArrayConverter converter = DataToByteArrayConverter();
  FileHelper fileHelper = FileHelper();
  InlineImageProvider controllerData = GetIt.instance<InlineImageProvider>();

  Future<List<List<int>>> generateDataChunk() async {
    return converter.convert(data);
  }
}
