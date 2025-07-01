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
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  String _cachedText = ''; // Cache text on pause
  late AnimationBadgeProvider _animationProvider;
  late InlineImageProvider _inlineImageProvider;
  late final TabController _tabController;
  // Providers are now accessed via context; removed direct instantiation.

  ImageUtils imageUtils = ImageUtils();

  bool isPrefixIconClicked = false;
  int textfieldLength = 0;
  String previousText = '';
  late TextEditingController inlineimagecontroller;
  bool isDialInteracting = false;
  String errorVal = "";

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this); // Register observer
    _setPortraitOrientation();
    _startImageCaching();
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  bool _controllerListenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationProvider =
        Provider.of<AnimationBadgeProvider>(context, listen: false);
    _inlineImageProvider =
        Provider.of<InlineImageProvider>(context, listen: false);
    inlineimagecontroller = _inlineImageProvider.getController();
    inlineimagecontroller.addListener(handleTextChange);
    if (!_controllerListenerAdded) {
      _inlineImageProvider.getController().addListener(_controllerListner);
      _controllerListenerAdded = true;
    }
    // Set context if needed by InlineImageProvider
    _inlineImageProvider.setContext(context);
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
  }

  void _controllerListner() {
    final animationProvider =
        Provider.of<AnimationBadgeProvider>(context, listen: false);
    final inlineImageProvider =
        Provider.of<InlineImageProvider>(context, listen: false);
    animationProvider.badgeAnimation(
      inlineImageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister observer
    inlineimagecontroller.removeListener(handleTextChange);
    _animationProvider.stopAnimation();
    _inlineImageProvider.getController().removeListener(_controllerListner);
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
    final provider = Provider.of<InlineImageProvider>(context, listen: false);
    if (!provider.isCacheInitialized) {
      await provider.generateImageCache();
      setState(() {
        provider.isCacheInitialized = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cachedText = inlineimagecontroller.text;
      _animationProvider.stopAnimation();
    } else if (state == AppLifecycleState.resumed) {
      if (inlineimagecontroller.text.trim().isEmpty &&
          _cachedText.trim().isNotEmpty) {
        inlineimagecontroller.text = _cachedText;
      }
      _animationProvider.badgeAnimation(
        inlineimagecontroller.text,
        Converters(),
        _animationProvider.isEffectActive(InvertLEDEffect()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final animationProvider = context.watch<AnimationBadgeProvider>();
    final speedDialProvider = context.watch<SpeedDialProvider>();
    final badgeData = context.read<BadgeMessageProvider>();
    final inlineImageProvider = context.watch<InlineImageProvider>();

    // Listener registration moved to didChangeDependencies to avoid multiple adds.
    return DefaultTabController(
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
                    child: ExtendedTextField(
                      onChanged: (value) {},
                      controller: inlineimagecontroller,
                      specialTextSpanBuilder: ImageBuilder(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        prefixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isPrefixIconClicked = !isPrefixIconClicked;
                            });
                          },
                          icon: const Icon(Icons.tag_faces_outlined),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.r)),
                          borderSide: BorderSide(color: colorPrimary),
                        ),
                      ),
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
                        child: VectorGridView())),
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
                  height: 250.h, // Adjust the height dynamically
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      GestureDetector(
                          onPanDown: (_) {
                            // Enter interaction mode to stop main scrolling
                            setState(() => isDialInteracting = true);
                          },
                          onPanCancel: () {
                            // Exit interaction mode if interaction is cancelled
                            setState(() => isDialInteracting = false);
                          },
                          onPanEnd: (_) {
                            // Re-enable main scroll when done interacting
                            setState(() => isDialInteracting = false);
                          },
                          child: RadialDial()),
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
                                  context: this.context,
                                  builder: (context) {
                                    return SaveBadgeDialog(
                                      speed: speedDialProvider,
                                      animationProvider: animationProvider,
                                      textController:
                                          inlineImageProvider.getController(),
                                      isInverse: animationProvider
                                          .isEffectActive(InvertLEDEffect()),
                                    );
                                  });
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
                    SizedBox(
                      width: 100.w,
                    ),
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
                                  false);
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
                )
              ],
            ),
          ),
        ),
        scaffoldKey: const Key(homeScreenTitleKey),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
