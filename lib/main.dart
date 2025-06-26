import 'package:badgemagic/providers/getitlocator.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/view/about_us_screen.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:badgemagic/view/saved_clipart.dart';
import 'package:badgemagic/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'globals/globals.dart' as globals;
import 'bademagic_module/utils/locale_persistence.dart';

void main() {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<InlineImageProvider>(
          create: (context) => getIt<InlineImageProvider>()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  void _loadSavedLocale() async {
    Locale? saved = await LocalePersistence.loadLocale();
    if (saved != null) {
      setState(() {
        _locale = saved;
      });
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LocalePersistence.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          scaffoldMessengerKey: globals.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.white,
            useMaterial3: true,
          ),
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
            Locale('es'),
          ],
          initialRoute: '/',
          onGenerateRoute: (settings) {
            if (settings.name == '/settings') {
              return MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  onLocaleChange: setLocale,
                ),
              );
            }
            // fallback to default
            final routes = <String, WidgetBuilder>{
              '/': (context) => const HomeScreen(),
              '/drawBadge': (context) => const DrawBadge(),
              '/savedBadge': (context) => const SaveBadgeScreen(),
              '/savedClipart': (context) => const SavedClipart(),
              '/aboutUs': (context) => const AboutUsScreen(),
            };
            final builder = routes[settings.name];
            if (builder != null) {
              return MaterialPageRoute(builder: builder);
            }
            return null;
          },
        );
      },
    );
  }
}
