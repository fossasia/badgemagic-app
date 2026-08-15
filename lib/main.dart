import 'dart:math' as math;

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/badge_scan_provider.dart';
import 'package:badgemagic/providers/service_locator.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/view/about_us_screen.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/home_screen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:badgemagic/view/saved_clipart_screen.dart';
import 'package:badgemagic/view/settings_screen.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/others/globals.dart' as globals;
import 'package:badgemagic/others/localization_service.dart';

Future<void> main() async {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();

  final localizationService = getIt<LocalizationService>();
  getIt.registerLazySingleton<BleDialogController>(() => BleDialogController());
  final saved = await localizationService.loadSavedLocale();
  appLocale.value = const Locale('en');
  await localizationService.init(appLocale.value ?? const Locale('en'));
  if (saved != null && saved.languageCode != 'en') {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      appLocale.value = saved;
      await localizationService.updateLocale(saved);
    });
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<InlineImageProvider>(
          create: (context) => getIt<InlineImageProvider>()),
      ChangeNotifierProvider<FontProvider>(
          create: (context) => getIt<FontProvider>()),
      ChangeNotifierProvider<BadgeScanProvider>(
        create: (_) => getIt<BadgeScanProvider>(),
      ),
      ChangeNotifierProvider<AnimationBadgeProvider>(
        create: (_) => AnimationBadgeProvider(),
      ),
      ChangeNotifierProvider<SpeedDialProvider>(
        create: (ctx) => SpeedDialProvider(ctx.read<AnimationBadgeProvider>()),
      ),
    ],
    child: const MyApp(),
  ));
}

final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildApp(context, constraints.biggest),
    );
  }

  Widget _buildApp(BuildContext context, Size window) {
    const double designPhoneWidth = 360.0;
    const double phoneMaxWidth = 480.0;
    const double phoneDiagonal = 859.0;
    const double minDesktopScale = 1.0;
    const double maxDesktopScale = 2.0;

    final double w =
        window.width.isFinite && window.width > 0 ? window.width : 360.0;
    final double h =
        window.height.isFinite && window.height > 0 ? window.height : 780.0;

    final double scale = w <= phoneMaxWidth
        ? w / designPhoneWidth
        : (math.sqrt(w * w + h * h) / phoneDiagonal)
            .clamp(minDesktopScale, maxDesktopScale);

    final double designWidth = w / scale;
    final double designHeight = h / scale;
    return ScreenUtilInit(
      designSize: Size(designWidth, designHeight),
      builder: (context, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            if (locale != null) {
              getIt<LocalizationService>().updateLocale(locale);
            }
            return MaterialApp(
              scaffoldMessengerKey: globals.scaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorSchemeSeed: colorSurface,
                useMaterial3: true,
                dialogTheme: DialogThemeData(
                  backgroundColor: colorSurface,
                  surfaceTintColor: colorTransparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.0),
                  ),
                  actionsPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorOnSurface,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: colorError,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
              locale: locale ?? const Locale('en', 'US'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
                Locale('it'),
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) return supportedLocales.first;
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              initialRoute: '/',
              routes: {
                '/': (context) => const HomeScreen(),
                '/drawBadge': (context) => const DrawBadge(),
                '/savedBadge': (context) => const SaveBadgeScreen(),
                '/savedClipart': (context) => const SavedClipart(),
                '/aboutUs': (context) => const AboutUsScreen(),
                '/settings': (context) => const SettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
