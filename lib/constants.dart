import 'dart:ui';

import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:url_launcher/url_launcher.dart';

const homeScreenTitleKey = "bm_hm_title";
const drawBadgeScreen = "bm_db_screen";
const savedClipartScreen = "bm_sc_screen";
const savedBadgeScreen = "bm_sb_screen";

//Colors used in the app
// Primary Colors
const Color colorPrimary = Color(0xFFD32F2F);
const Color colorPrimaryDark = Color(0xFFC72C2C);
const Color colorAccent = Color(0xFFD32F2F);

// Knob Colors
const Color backCircleColor = Color(0xFFEDEDED);
const Color indicatorColor = Color(0xFFD32F2F);
const Color progressSecondaryColor = Color(0xFFEEEEEE);

// Additional Colors
const Color mdGrey400 = Color(0xFFBDBDBD);
const Color dividerColor = Color(0xFFE0E0E0);
const Color drawerHeaderTitle = Color(0xFFFFFFFF);

//path to all the animation assets used
const String animation = 'assets/animations/ic_anim_animation.gif';
const String aniLeft = 'assets/animations/ic_anim_left.gif';
const String aniDown = 'assets/animations/ic_anim_down.gif';
const String aniFixed = 'assets/animations/ic_anim_fixed.gif';
const String aniLaser = 'assets/animations/ic_anim_laser.gif';
const String aniPicture = 'assets/animations/ic_anim_picture.gif';
const String aniUp = 'assets/animations/ic_anim_up.gif';
const String aniRight = 'assets/animations/ic_anim_right.gif';
const String aniPacman = 'assets/animations/ic_anim_pacman.gif';
const String aniChevronLeft = 'assets/animations/ic_anim_chevron_left.gif';
const String aniDiamond = 'assets/animations/ic_anim_diamond.gif';
const String aniBrokenHearts = 'assets/animations/ic_anim_broken_hearts.gif';
const String aniSnowflake = 'assets/animations/ic_anim_snowflake.gif';

//path to all the effects assets used
const String effFlash = 'assets/effects/ic_effect_flash.gif';
const String effInvert = 'assets/effects/ic_effect_invert.gif';
const String effMarque = 'assets/effects/ic_effect_marquee.gif';

//constants for the animation speed
const Duration aniBaseSpeed =
    Duration(microseconds: 400000); // in uS (slower for badge match)
const Duration aniMarqueSpeed = Duration(microseconds: 100000); // in uS
const Duration aniFlashSpeed = Duration(microseconds: 500000); // in uS

// Function to calculate animation speed based on speed level
int aniSpeedStrategy(int speedLevel) {
  // Make sure the minimum speed is not too fast
  int minSpeed = 100000; // 100ms per frame (badge max speed)
  int speedInMicroseconds = aniBaseSpeed.inMicroseconds -
      (speedLevel * (aniBaseSpeed.inMicroseconds - minSpeed) ~/ 8);
  return speedInMicroseconds;
}

Future<void> openUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) {
    ToastUtils().showErrorToast('Failed to launch url please try again');
  } else {
    await launchUrl(uri);
  }
}
