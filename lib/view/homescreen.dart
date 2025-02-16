import 'dart:async';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late AnimationBadgeProvider animationProvider;
  late SpeedDialProvider speedDialProvider;
  BadgeMessageProvider badgeData = BadgeMessageProvider();
  ImageUtils imageUtils = ImageUtils();
  InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  bool isPrefixIconClicked = false;
  int textfieldLength = 0;
  String previousText = '';
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();
  bool isDialInteracting = false;
  String errorVal = "";

  // Font-related variables
  String selectedFont = 'Roboto';
  double fontSize = 16.0;
  Color textColor = Colors.black;

  final List<String> googleFonts = [
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Poppins',
    'Raleway',
    'Ubuntu',
    'Playfair Display',
    'Source Sans Pro',
    'Dancing Script'
  ];

  TextStyle _getGoogleFont(String fontName) {
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize,
        color: textColor,
      );
    } catch (e) {
      //print('Error loading font $fontName: $e');
      return GoogleFonts.roboto(
        fontSize: fontSize,
        color: textColor,
      );
    }
  }

  @override
  void initState() {
    animationProvider = AnimationBadgeProvider();
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inlineImageProvider.setContext(context);
    });
    _startImageCaching();
    speedDialProvider = SpeedDialProvider(animationProvider);
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;
    final selection = inlineimagecontroller.selection;

    if (previousText.length > currentText.length) {
      final deletionIndex = selection.baseOffset;
      final regex = RegExp(r'<<\d+>>');
      final matches = regex.allMatches(previousText);

      bool placeholderDeleted = false;

      for (final match in matches) {
        if (deletionIndex > match.start && deletionIndex < match.end) {
          inlineimagecontroller.text =
              previousText.replaceRange(match.start, match.end, '');
          inlineimagecontroller.selection =
              TextSelection.collapsed(offset: match.start);
          placeholderDeleted = true;
          break;
        }
      }

      if (!placeholderDeleted) {
        previousText = inlineimagecontroller.text;
      }
    } else {
      previousText = currentText;
    }
    _controllerListner();
  }

  void _controllerListner() {
    animationProvider.badgeAnimation(
      inlineImageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
      textStyle: _getGoogleFont(selectedFont),
    );
  }

  @override
  void dispose() {
    inlineimagecontroller.removeListener(handleTextChange);
    animationProvider.stopAnimation();
    animationProvider.dispose();
    inlineImageProvider.getController().removeListener(_controllerListner);
    _tabController.dispose();
    super.dispose();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _startImageCaching() async {
    if (!inlineImageProvider.isCacheInitialized) {
      await inlineImageProvider.generateImageCache();
      setState(() {
        inlineImageProvider.isCacheInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: animationProvider),
        ChangeNotifierProvider(
          create: (context) => SpeedDialProvider(animationProvider),
        ),
      ],
      child: DefaultTabController(
        length: 3,
        child: CommonScaffold(
          index: 0,
          title: 'Badge Magic',
          body: SafeArea(
            child: SingleChildScrollView(
              physics: isDialInteracting
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  AnimationBadge(),
                  Container(
                    margin: EdgeInsets.all(15.w),
                    child: Material(
                      color: drawerHeaderTitle,
                      borderRadius: BorderRadius.circular(10.r),
                      elevation: 4,
                      child: Row(
                        children: [
                          Expanded(
                            child: ExtendedTextField(
                              onChanged: (value) {},
                              controller: inlineimagecontroller,
                              specialTextSpanBuilder: ImageBuilder(),
                              style: _getGoogleFont(selectedFont),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                prefixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isPrefixIconClicked =
                                          !isPrefixIconClicked;
                                    });
                                  },
                                  icon: const Icon(Icons.tag_faces_outlined),
                                ),
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: PopupMenuButton<String>(
                                    icon: Icon(Icons.text_fields,
                                        color: Colors.grey[700]),
                                    onSelected: (String value) {
                                      setState(() {
                                        selectedFont = value;
                                        _controllerListner();
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return googleFonts.map((String font) {
                                        return PopupMenuItem<String>(
                                          value: font,
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              font,
                                              style: _getGoogleFont(font),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                hintText: 'Type your message...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isPrefixIconClicked,
                    child: Container(
                      height: 170.h,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: Colors.grey[200]),
                      margin: EdgeInsets.symmetric(horizontal: 15.w),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.w),
                      child: VectorGridView(),
                    ),
                  ),
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: mdGrey400,
                    indicatorColor: colorPrimary,
                    controller: _tabController,
                    splashFactory: InkRipple.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return dividerColor;
                        }
                        return null;
                      },
                    ),
                    tabs: const [
                      Tab(text: 'Speed'),
                      Tab(text: 'Animation'),
                      Tab(text: 'Effects'),
                    ],
                  ),
                  SizedBox(
                    height: 250.h,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        GestureDetector(
                          onPanDown: (_) =>
                              setState(() => isDialInteracting = true),
                          onPanCancel: () =>
                              setState(() => isDialInteracting = false),
                          onPanEnd: (_) =>
                              setState(() => isDialInteracting = false),
                          child: RadialDial(),
                        ),
                        AnimationTab(),
                        EffectTab(),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                logger.i(
                                    'Save button clicked, showing dialog : ${animationProvider.isEffectActive(FlashEffect())}');
                                showDialog(
                                  context: context,
                                  builder: (context) => SaveBadgeDialog(
                                    speed: speedDialProvider,
                                    animationProvider: animationProvider,
                                    textController:
                                        inlineImageProvider.getController(),
                                    isInverse: animationProvider
                                        .isEffectActive(InvertLEDEffect()),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 33.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.r),
                                  color: mdGrey400,
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 100.w),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                badgeData.checkAndTransfer(
                                  inlineImageProvider.getController().text,
                                  animationProvider
                                      .isEffectActive(FlashEffect()),
                                  animationProvider
                                      .isEffectActive(MarqueeEffect()),
                                  animationProvider
                                      .isEffectActive(InvertLEDEffect()),
                                  speedDialProvider.getOuterValue(),
                                  modeValueMap[
                                      animationProvider.getAnimationIndex()],
                                  null,
                                  false,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.r),
                                  color: mdGrey400,
                                ),
                                child: const Text('Transfer'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          scaffoldKey: const Key(homeScreenTitleKey),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
