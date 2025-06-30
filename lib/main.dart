import 'package:badgemagic/providers/getitlocator.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/view/about_us_screen.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:badgemagic/view/saved_clipart.dart';
import 'package:badgemagic/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'globals/globals.dart' as globals;

void main() {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<InlineImageProvider>(
        create: (context) => getIt<InlineImageProvider>(),
      ),
      ChangeNotifierProvider<AnimationBadgeProvider>(
        create: (context) => AnimationBadgeProvider(),
      ),
      ChangeNotifierProxyProvider<AnimationBadgeProvider, SpeedDialProvider>(
        create: (context) =>
            SpeedDialProvider(context.read<AnimationBadgeProvider>()),
        update: (context, animationProvider, speedDialProvider) =>
            speedDialProvider!..badgeProvider = animationProvider,
      ),
      Provider<BadgeMessageProvider>(
        create: (context) => BadgeMessageProvider(),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  }
}
