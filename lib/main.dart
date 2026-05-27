import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/providers/getitlocator.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/view/about_us_screen.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:badgemagic/view/saved_clipart.dart';
import 'package:badgemagic/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'globals/globals.dart' as globals;
import 'services/localization_service.dart';

Future<void> main() async {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global localization service for usage outside of widgets
  final localizationService = getIt<LocalizationService>();
  // Keep initial UI in English for integration tests that tap by English text
  // Apply saved locale on the next frame so visible strings change after first paint
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
    ],
    child: const MyApp(),
  ));
}

// Locale notifier for dynamic switching
final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            // Keep LocalizationService in sync when locale changes
            if (locale != null) {
              getIt<LocalizationService>().updateLocale(locale);
            }
            return MaterialApp(
              scaffoldMessengerKey: globals.scaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorSchemeSeed: Colors.white,
                useMaterial3: true,
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
