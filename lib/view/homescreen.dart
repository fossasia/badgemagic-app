import 'dart:async';
import 'package:badgemagic/bademagic_module/utils/badge_text_storage.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
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
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  // Add parameters for saved badge data when editing
  final Map<String, dynamic>? savedBadgeData;
  final String? savedBadgeFilename;

  const HomeScreen({
    super.key,
    this.savedBadgeData,
    this.savedBadgeFilename,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
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

  @override
  void initState() {
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inlineImageProvider.setContext(context);

      // Apply saved badge data if we're editing a saved badge
      if (widget.savedBadgeData != null) {
        await _applySavedBadgeData();
      }
    });
    _startImageCaching();
    speedDialProvider = SpeedDialProvider(animationProvider);
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  // Method to apply saved badge data when editing a badge
  Future<void> _applySavedBadgeData() async {
    final savedData = widget.savedBadgeData!;
    final fileHelper = FileHelper();
    final savedBadgeProvider = SavedBadgeProvider();

    // Set the text from the saved badge
    final badgeData = fileHelper.jsonToData(savedData);
    final message = badgeData.messages[0];

    // When we save a badge, we store the original text using BadgeTextStorage
    // Now we need to retrieve that text to show in the text field

    String badgeText = "";
    try {
      if (widget.savedBadgeFilename != null) {
        // Get the original text from BadgeTextStorage
        badgeText =
            await BadgeTextStorage.getOriginalText(widget.savedBadgeFilename!);

        // If we couldn't find the original text, use the filename as a fallback
        if (badgeText.isEmpty) {
          badgeText = widget.savedBadgeFilename!
              .substring(0, widget.savedBadgeFilename!.length - 5);
          // If the filename is a timestamp, use a generic text
          if (badgeText.contains(":") && badgeText.contains("-")) {
            badgeText = "Hello"; // Default text for timestamp filenames
          }
        }
      }
    } catch (e) {
      logger.e("Failed to retrieve original badge text: $e");
      badgeText = "Hello"; // Default fallback
    }

    // Set the text in the controller
    inlineimagecontroller.text = badgeText;

    // Set animation effects
    if (message.flash) {
      animationProvider.addEffect(effectMap[1]); // Flash effect
    }
    if (message.marquee) {
      animationProvider.addEffect(effectMap[2]); // Marquee effect
    }

    // Set inversion if applicable
    if (savedData.containsKey('invert') && savedData['invert'] == true) {
      animationProvider.addEffect(effectMap[0]); // Invert effect
    }

    // Set animation mode
    int modeValue = 0; // Default to left animation
    try {
      // Handle different mode formats - could be enum or int
      if (message.mode is int) {
        modeValue = message.mode as int;
      } else {
        // Try to extract the mode value from the enum
        String modeString = message.mode.toString();
        // If it's in format "Mode.left", extract just the mode name
        if (modeString.contains('.')) {
          String modeName = modeString.split('.').last;
          // Map mode name to value
          switch (modeName.toLowerCase()) {
            case 'left':
              modeValue = 0;
              break;
            case 'right':
              modeValue = 1;
              break;
            case 'up':
              modeValue = 2;
              break;
            case 'down':
              modeValue = 3;
              break;
            case 'fixed':
              modeValue = 4;
              break;
            case 'snowflake':
              modeValue = 5;
              break;
            case 'picture':
              modeValue = 6;
              break;
            case 'animation':
              modeValue = 7;
              break;
            default:
              modeValue = 0; // Default to left
          }
        } else {
          // Try parsing as int
          modeValue = int.tryParse(modeString) ?? 0;
        }
      }
    } catch (e) {
      // If parsing fails, default to left animation (0)
      logger.e("Failed to parse mode value: $e");
    }
    animationProvider.setAnimationMode(animationMap[modeValue]);

    // Set speed using Speed.getIntValue to ensure correct dial value
    try {
      int speedDialValue = 1; // Default
      // Use the static helper method to get the correct dial value
      speedDialValue = Speed.getIntValue(message.speed);
      logger
          .i("Setting speed dial to: $speedDialValue from ${message.speed}");
          speedDialProvider.setDialValue(speedDialValue);
    } catch (e) {
      logger.e("Failed to set speed dial value: $e");
      speedDialProvider.setDialValue(1); // Fallback to default
    }

    // Store the filename for saving back to the same file
    savedBadgeProvider.setSavedBadgeDataMap(savedData);
    savedBadgeProvider.setIsSavedBadgeData(true);

    // Notify that we're editing an existing badge
    ToastUtils().showToast(
        "Editing badge: ${widget.savedBadgeFilename!.substring(0, widget.savedBadgeFilename!.length - 5)}");
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
    animationProvider.badgeAnimation(inlineImageProvider.getController().text,
        Converters(), animationProvider.isEffectActive(InvertLEDEffect()));
  }

  @override
  void dispose() {
    inlineimagecontroller.removeListener(handleTextChange);
    animationProvider.stopAnimation();
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
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (context) => animationProvider,
        ),
        ChangeNotifierProvider<SpeedDialProvider>(
          create: (context) {
            inlineImageProvider.getController().addListener(_controllerListner);
            return speedDialProvider;
          },
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.r)),
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
                                onTap: () async {
                                  if (inlineImageProvider
                                      .getController()
                                      .text
                                      .isEmpty) {
                                    ToastUtils()
                                        .showToast("Please enter a message");
                                    return;
                                  }
                                  logger.i(
                                      'Save button clicked, showing dialog : ${animationProvider.isEffectActive(FlashEffect())}');
                                  // If we're editing an existing badge, update it instead of showing save dialog
                                  if (widget.savedBadgeFilename != null) {
                                    // Update the existing badge file using the new updateBadgeData method
                                    SavedBadgeProvider savedBadgeProvider =
                                        SavedBadgeProvider();
                                    // Extract the base filename without .json extension
                                    String baseFilename =
                                        widget.savedBadgeFilename!;
                                    if (baseFilename.endsWith('.json')) {
                                      baseFilename = baseFilename.substring(
                                          0, baseFilename.length - 5);
                                    }

                                    logger.i(
                                        'Updating existing badge: $baseFilename');

                                    // Use the new updateBadgeData method which handles everything cleanly
                                    await savedBadgeProvider.updateBadgeData(
                                        baseFilename, // Pass the filename without .json extension
                                        inlineImageProvider
                                            .getController()
                                            .text,
                                        animationProvider
                                            .isEffectActive(FlashEffect()),
                                        animationProvider
                                            .isEffectActive(MarqueeEffect()),
                                        animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                        speedDialProvider.getOuterValue(),
                                        animationProvider.getAnimationIndex() ??
                                            1);
                                    ToastUtils().showToast(
                                        "Badge Updated Successfully");
                                  } else {
                                    // Show save dialog for new badges
                                    showDialog(
                                        context: this.context,
                                        builder: (context) {
                                          return SaveBadgeDialog(
                                            speed: speedDialProvider,
                                            animationProvider:
                                                animationProvider,
                                            textController: inlineImageProvider
                                                .getController(),
                                            isInverse: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                          );
                                        });
                                  }
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
                                      modeValueMap[animationProvider
                                          .getAnimationIndex()],
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
          )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
