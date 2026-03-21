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
  // Must be called first — platform channels are required during
  // service registration (e.g. path_provider, shared_preferences).
  WidgetsFlutterBinding.ensureInitialized(); // ✅ BUG-01: moved before setupLocator()

  setupLocator();

  // Initialize global localization service for usage outside of widgets.
  // Ensure init() completes before runApp() so l10n is never null.
  final localizationService = getIt<LocalizationService>();
  final saved = await localizationService.loadSavedLocale();

  // Keep initial UI in English for integration tests that tap by English text.
  appLocale.value = const Locale('en');
  await localizationService.init(appLocale.value ?? const Locale('en'));

  // Apply saved locale on the next frame so visible strings change after first paint.
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<InlineImageProvider>(
          create: (_) => getIt<InlineImageProvider>(),
        ),
        ChangeNotifierProvider<FontProvider>(
          create: (_) => getIt<FontProvider>(),
        ),
        ChangeNotifierProvider<BadgeScanProvider>(
          create: (_) => getIt<BadgeScanProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Locale notifier for dynamic language switching without full app restart.
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
            // Keep LocalizationService in sync whenever locale changes.
            if (locale != null) {
              getIt<LocalizationService>().updateLocale(locale);
            }

            return MaterialApp(
              scaffoldMessengerKey: globals.scaffoldMessengerKey,
              debugShowCheckedModeBanner: false,

              // TODO(PROD): Replace with AppTheme.light / AppTheme.dark
              // once dark mode support is added (see review FEAT-01).
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
                for (final supported in supportedLocales) {
                  if (supported.languageCode == locale.languageCode) {
                    return supported;
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
