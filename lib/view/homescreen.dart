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
import 'package:badgemagic/view/game_selection_screen.dart';
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
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  // 0 = Badge tab, 1 = Game tab
  int _selectedIndex = 0;

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
    WidgetsBinding.instance.addObserver(this);
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
    final badgeDataModel = fileHelper.jsonToData(savedData);
    final message = badgeDataModel.messages[0];

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
      logger.i("Setting speed dial to: $speedDialValue from ${message.speed}");
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
    animationProvider.badgeAnimation(
      inlineImageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    // Depending on _selectedIndex, we either show the badge‐editing UI (index 0)
    // or the game selection UI (index 1).
    final Widget bodyContent = (_selectedIndex == 0)
        ? _buildBadgeBody(inlineImageProvider)
        : GameSelectionScreen();

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
          index: _selectedIndex,
          title: 'Badge Magic',
          scaffoldKey: const Key(homeScreenTitleKey),
          body: SafeArea(
            child: Column(
              children: [
                // Main content area (badge UI or game screen)
                Expanded(child: bodyContent),
                // Bottom navigation always shows
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the badge-editing UI (when _selectedIndex == 0).
  Widget _buildBadgeBody(InlineImageProvider inlineImageProvider) {
    return SingleChildScrollView(
      physics: isDialInteracting
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // The animated badge preview
          const AnimationBadge(),

          // Text‐entry area with inline-image support
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

          // If the emoji/inlined‐image palette is open
          Visibility(
            visible: isPrefixIconClicked,
            child: Container(
              height: 170.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: Colors.grey[200],
              ),
              margin: EdgeInsets.symmetric(horizontal: 15.w),
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              child: const VectorGridView(),
            ),
          ),

          // TabBar (Speed / Animation / Effects)
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

          // The TabBarView that shows the dials / toggles
          SizedBox(
            height: 250.h,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                GestureDetector(
                  onPanDown: (_) {
                    // Enter interaction mode to stop scrolling
                    setState(() => isDialInteracting = true);
                  },
                  onPanCancel: () {
                    setState(() => isDialInteracting = false);
                  },
                  onPanEnd: (_) {
                    setState(() => isDialInteracting = false);
                  },
                  child: const RadialDial(),
                ),
                const AnimationTab(),
                const EffectTab(),
              ],
            ),
          ),

          // Save / Transfer buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Save Button
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (inlineImageProvider.getController().text.isEmpty) {
                          ToastUtils().showToast("Please enter a message");
                          return;
                        }

                        // If we're editing an existing badge, update it
                        if (widget.savedBadgeFilename != null) {
                          final savedBadgeProvider = SavedBadgeProvider();
                          String baseFilename = widget.savedBadgeFilename!;
                          if (baseFilename.endsWith('.json')) {
                            baseFilename = baseFilename.substring(
                                0, baseFilename.length - 5);
                          }

                          await savedBadgeProvider.updateBadgeData(
                            baseFilename,
                            inlineImageProvider.getController().text,
                            animationProvider.isEffectActive(FlashEffect()),
                            animationProvider.isEffectActive(MarqueeEffect()),
                            animationProvider.isEffectActive(InvertLEDEffect()),
                            speedDialProvider.getOuterValue(),
                            animationProvider.getAnimationIndex() ?? 1,
                          );
                          ToastUtils().showToast("Badge Updated Successfully");
                        } else {
                          // Show dialog for new badge
                          showDialog(
                            context: context,
                            builder: (context) {
                              return SaveBadgeDialog(
                                speed: speedDialProvider,
                                animationProvider: animationProvider,
                                textController:
                                    inlineImageProvider.getController(),
                                isInverse: animationProvider
                                    .isEffectActive(InvertLEDEffect()),
                              );
                            },
                          );
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

              SizedBox(width: 100.w),

              // Transfer Button
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        badgeData.checkAndTransfer(
                          inlineImageProvider.getController().text,
                          animationProvider.isEffectActive(FlashEffect()),
                          animationProvider.isEffectActive(MarqueeEffect()),
                          animationProvider.isEffectActive(InvertLEDEffect()),
                          speedDialProvider.getOuterValue(),
                          modeValueMap[animationProvider.getAnimationIndex()],
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
    );
  }

  /// Builds the bottom navigation row. Tapping “Badge” sets index=0; tapping “Game” sets index=1.
  Widget _buildBottomNavigation() {
    // Determine whether each button is selected
    final bool isBadgeSelected = (_selectedIndex == 0);
    final bool isGameSelected = (_selectedIndex == 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Badge button
            InkWell(
              onTap: () {
                if (_selectedIndex != 0) {
                  setState(() {
                    _selectedIndex = 0;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isBadgeSelected
                      ? colorPrimary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge,
                      color: isBadgeSelected ? colorPrimary : Colors.grey,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Badge',
                      style: TextStyle(
                        color: isBadgeSelected ? colorPrimary : Colors.grey,
                        fontWeight: isBadgeSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Game button
            InkWell(
              onTap: () {
                if (_selectedIndex != 1) {
                  setState(() {
                    _selectedIndex = 1;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isGameSelected
                      ? colorPrimary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gamepad,
                      color: isGameSelected ? colorPrimary : Colors.grey,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Game',
                      style: TextStyle(
                        color: isGameSelected ? colorPrimary : Colors.grey,
                        fontWeight: isGameSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      inlineimagecontroller.clear();
      previousText = '';
      animationProvider.stopAllAnimations.call(); // If method exists
      animationProvider.initializeAnimation.call(); // If method exists
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      animationProvider.stopAnimation();
    }
  }
}
