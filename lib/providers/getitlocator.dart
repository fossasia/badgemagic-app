import 'package:badgemagic/providers/imageprovider.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<InlineImageProvider>(() => InlineImageProvider());
}
