import 'package:badgemagic/others/app_logger.dart' as app;
import 'package:badgemagic/others/byte_array_utils.dart' as bytes;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('byte_array_utils re-exports the single shared logger', () {
    expect(identical(app.logger, bytes.logger), isTrue);
  });
}
