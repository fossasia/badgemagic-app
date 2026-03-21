import 'dart:async';

import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/badge_loader_helper.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/main.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/transitiontab.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  final String? savedBadgeFilename;
  final int? initialSpeed;

  const HomeScreen({
    super.key,
    this.savedBadgeFilename,
    this.initialSpeed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  // ── Logger ────────────────────────────────────────────────────────────────
  // FIX BUG-05: use logger instead of print() everywhere in this file.
  static final Logger _logger = Logger();

  // ── Controllers & providers ───────────────────────────────────────────────
  late final TabController _tabController;
  late final ScrollController _vectorScrollController;

  final AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
  late final SpeedDialProvider speedDialProvider;
  final BadgeMessageProvider badgeData = BadgeMessageProvider();

  // FIX QC-03: single field declaration — never re-declared as a local
  // variable inside build(), which was silently shadowing this field and
  // causing lambda capture confusion.
  final InlineImageProvider _imageProvider =
      GetIt.instance<InlineImageProvider>();

  final TextEditingController _textController =
      GetIt.instance<InlineImageProvider>().getController();

  // ── UI state ──────────────────────────────────────────────────────────────
  bool _isEmojiPickerVisible = false;
  bool _isDialInteracting = false;
  String _previousText = '';
  String _cachedText = '';

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _vectorScrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_handleTextChange);
    _setPortraitOrientation();

    speedDialProvider = SpeedDialProvider(animationProvider);

    if (widget.initialSpeed != null) {
      speedDialProvider.setDialValue(widget.initialSpeed!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _imageProvider.setContext(context);
      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }
    });

    _startImageCaching();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _vectorScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_handleTextChange);
    _textController.removeListener(_onControllerChanged);
    animationProvider.stopAnimation();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // Restore cached text if cleared while in background.
        if (_textController.text.trim().isEmpty &&
            _cachedText.trim().isNotEmpty) {
          _textController.text = _cachedText;
        }
        animationProvider.badgeAnimation(
          _textController.text,
          Converters(),
          animationProvider.isEffectActive(InvertLEDEffect()),
        );
        if (mounted) setState(() {});
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _cachedText = _textController.text;
        animationProvider.stopAnimation();
      default:
        break;
    }
  }

  @override
  bool get wantKeepAlive => true;

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _startImageCaching() async {
    if (!_imageProvider.isCacheInitialized) {
      await _imageProvider.generateImageCache();
      if (mounted) {
        setState(() => _imageProvider.isCacheInitialized = true);
      }
    }
  }

  /// Loads a previously saved badge from disk and restores all of its
  /// settings (text, effects, animation mode, speed) to the active providers.
  Future<void> _loadBadgeDataFromDisk(String badgeFilename) async {
    try {
      final (badgeText, loadedData, savedData) =
          await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);

      _textController.text = badgeText;

      // Clear any lingering effects before applying the saved ones.
      animationProvider.removeEffect(effectMap[0]);
      animationProvider.removeEffect(effectMap[1]);
      animationProvider.removeEffect(effectMap[2]);

      final message = loadedData.messages[0];
      if (message.flash) animationProvider.addEffect(effectMap[1]);
      if (message.marquee) animationProvider.addEffect(effectMap[2]);
      if (savedData != null && savedData['invert'] == true) {
        animationProvider.addEffect(effectMap[0]);
      }

      final modeValue = BadgeLoaderHelper.parseAnimationMode(message.mode);
      animationProvider.setAnimationMode(animationMap[modeValue]);

      try {
        final speedDialValue = Speed.getIntValue(message.speed);
        speedDialProvider.setDialValue(speedDialValue);
      } catch (_) {
        speedDialProvider.setDialValue(1);
      }

      // FIX QC-07: localised toast — no more hardcoded English strings.
      // NOTE: Add 'editingBadge' key to app_en.arb if not present.
      final l10n = GetIt.instance<LocalizationService>().l10n;
      final displayName =
          badgeFilename.substring(0, badgeFilename.length - 5);
      ToastUtils().showToast('${l10n.editingBadge}: $displayName');
    } catch (e, stack) {
      // FIX BUG-05: replaced print() with _logger.e().
      _logger.e('Failed to load badge data', error: e, stackTrace: stack);
      final l10n = GetIt.instance<LocalizationService>().l10n;
      // NOTE: Add 'failedToLoadBadge' key to app_en.arb if not present.
      ToastUtils().showToast(l10n.failedToLoadBadge);
    }
  }

  /// Returns the [TextStyle] for a given [fontName].
  /// Used both in the text field preview and the font dropdown menu items.
  TextStyle _getFontStyle(String fontName) {
    const baseStyle = TextStyle(fontSize: 12);
    const bold = FontWeight.w700;
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Open Sans':
        return GoogleFonts.openSans(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Lato':
        return GoogleFonts.lato(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Poppins':
        return GoogleFonts.poppins(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Montserrat':
        return GoogleFonts.montserrat(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Orbitron':
        return GoogleFonts.orbitron(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      case 'Lexend':
        return GoogleFonts.lexend(
            textStyle: baseStyle.copyWith(fontWeight: bold));
      default:
        return baseStyle;
    }
  }

  /// Handles inline-image placeholder deletion when the user backspaces
  /// into a `<<N>>` token that wraps an embedded image.
  void _handleTextChange() {
    final currentText = _textController.text;
    final selection = _textController.selection;

    // Reset to text animation whenever the user types with a special animation
    // selected — special animations do not show user text.
    if (animationProvider.isSpecialAnimationSelected() &&
        currentText.isNotEmpty) {
      animationProvider.resetToTextAnimation();
      animationProvider.badgeAnimation(
        currentText,
        Converters(),
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
      setState(() {});
    }

    if (_previousText.length > currentText.length) {
      final deletionIndex = selection.baseOffset;
      final regex = RegExp(r'<<\d+>>');
      bool placeholderDeleted = false;

      for (final match in regex.allMatches(_previousText)) {
        if (deletionIndex > match.start && deletionIndex < match.end) {
          _textController.text =
              _previousText.replaceRange(match.start, match.end, '');
          _textController.selection =
              TextSelection.collapsed(offset: match.start);
          placeholderDeleted = true;
          break;
        }
      }
      if (!placeholderDeleted) _previousText = _textController.text;
    } else {
      _previousText = currentText;
    }
  }

  /// Triggers a badge animation re-render on every controller change.
  /// Added as a listener once [SpeedDialProvider] is created.
  void _onControllerChanged() {
    animationProvider.badgeAnimation(
      _imageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  /// Handles the Save button tap — updates an existing badge or opens the
  /// save dialog for a new one.
  Future<void> _onSaveTapped(
    AnimationBadgeProvider aniProvider,
    AppLocalizations l10n,
  ) async {
    if (_textController.text.trim().isEmpty) {
      // FIX QC-07: localised string.
      // NOTE: Add 'pleaseEnterMessage' key to app_en.arb if not present.
      ToastUtils().showToast(l10n.pleaseEnterMessage);
      return;
    }

    if (widget.savedBadgeFilename != null) {
      final savedBadgeProvider = SavedBadgeProvider();
      String baseFilename = widget.savedBadgeFilename!;
      if (baseFilename.endsWith('.json')) {
        baseFilename = baseFilename.substring(0, baseFilename.length - 5);
      }

      await savedBadgeProvider.updateBadgeData(
        baseFilename,
        _textController.text,
        aniProvider.isEffectActive(FlashEffect()),
        aniProvider.isEffectActive(MarqueeEffect()),
        aniProvider.isEffectActive(InvertLEDEffect()),
        speedDialProvider.getOuterValue(),
        aniProvider.getAnimationIndex() ?? 1,
      );

      // FIX QC-07: localised string.
      // NOTE: Add 'badgeUpdatedSuccessfully' key to app_en.arb if not present.
      ToastUtils().showToast(l10n.badgeUpdatedSuccessfully);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/savedBadge',
          (route) => false,
        );
      }
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => SaveBadgeDialog(
          speed: speedDialProvider,
          animationProvider: aniProvider,
          textController: _textController,
          isInverse: aniProvider.isEffectActive(InvertLEDEffect()),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // FIX QC-03: renamed from 'inlineImageProvider' to avoid shadowing the
    // instance field _imageProvider. Watches Provider tree for rebuilds only.
    final watchedImageProvider = Provider.of<InlineImageProvider>(context);

    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, _, __) {
        final l10n = GetIt.instance<LocalizationService>().l10n;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AnimationBadgeProvider>(
              create: (_) => animationProvider,
            ),
            ChangeNotifierProvider<SpeedDialProvider>(
              create: (_) {
                // Register the controller listener once — when the provider
                // is first created, not on every build().
                watchedImageProvider
                    .getController()
                    .addListener(_onControllerChanged);
                return speedDialProvider;
              },
            ),
          ],
          child: DefaultTabController(
            length: 4,
            child: CommonScaffold(
              index: 0,
              title: l10n.appTitle,
              scaffoldKey: const Key(homeScreenTitleKey),
              body: SafeArea(
                child: Stack(
                  children: [
                    // ── Scrollable main content ─────────────────────────
                    SingleChildScrollView(
                      physics: _isDialInteracting
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Live badge preview
                          AnimationBadge(),

                          // Text input + font selector  (UI-01)
                          _BadgeTextField(
                            controller: _textController,
                            isEmojiPickerVisible: _isEmojiPickerVisible,
                            onEmojiToggle: () => setState(
                              () => _isEmojiPickerVisible =
                                  !_isEmojiPickerVisible,
                            ),
                            getFontStyle: _getFontStyle,
                            animationProvider: animationProvider,
                          ),

                          // Emoji / vector picker panel
                          _EmojiPickerPanel(
                            isVisible: _isEmojiPickerVisible,
                            scrollController: _vectorScrollController,
                          ),

                          // Speed / Transition / Effects / Animation tabs
                          _BadgeTabBar(
                            controller: _tabController,
                            l10n: l10n,
                          ),

                          // Tab content
                          _BadgeTabBarView(
                            tabController: _tabController,
                            onDialPanDown: () =>
                                setState(() => _isDialInteracting = true),
                            onDialPanEnd: () =>
                                setState(() => _isDialInteracting = false),
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom action buttons (UI-02) ───────────────────
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Consumer<AnimationBadgeProvider>(
                          builder: (context, aniProvider, _) {
                            return _BadgeActionButtons(
                              l10n: l10n,
                              isSpecialAnimation:
                                  aniProvider.isSpecialAnimationSelected(),
                              onSave: () => _onSaveTapped(aniProvider, l10n),
                              onTransfer: () async {
                                await aniProvider.handleAnimationTransfer(
                                  badgeData: badgeData,
                                  inlineImageProvider: _imageProvider,
                                  speedDialProvider: speedDialProvider,
                                  flash: aniProvider
                                      .isEffectActive(FlashEffect()),
                                  marquee: aniProvider
                                      .isEffectActive(MarqueeEffect()),
                                  invert: aniProvider
                                      .isEffectActive(InvertLEDEffect()),
                                  context: context,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// UI-01: FontSelectorDropdown extracted from the 150-line inline dropdown.
// UI-02: BadgeActionButtons extracted from the inline Row.
// These are private to this file (_Xxx naming). Once stable, move each
// into its own file under lib/view/widgets/.
// ---------------------------------------------------------------------------

// ── Badge text input field ───────────────────────────────────────────────────

class _BadgeTextField extends StatelessWidget {
  const _BadgeTextField({
    required this.controller,
    required this.isEmojiPickerVisible,
    required this.onEmojiToggle,
    required this.getFontStyle,
    required this.animationProvider,
  });

  final TextEditingController controller;
  final bool isEmojiPickerVisible;
  final VoidCallback onEmojiToggle;
  final TextStyle Function(String) getFontStyle;
  final AnimationBadgeProvider animationProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      child: Material(
        color: drawerHeaderTitle,
        borderRadius: BorderRadius.circular(10.r),
        elevation: 4,
        child: Consumer<FontProvider>(
          builder: (context, fontProvider, _) {
            final selectedFont = fontProvider.selectedFont;
            return ExtendedTextField(
              // FIX: removed the original no-op `onChanged: (value) {}`.
              controller: controller,
              specialTextSpanBuilder: ImageBuilder(),
              style: selectedFont != null
                  ? getFontStyle(selectedFont).copyWith(fontSize: 14)
                  : const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: colorPrimary),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                prefixIcon: IconButton(
                  onPressed: onEmojiToggle,
                  icon: const Icon(Icons.tag_faces_outlined),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
                // UI-01: replaced the 150-line inline DropdownButton with
                // the extracted _FontSelectorDropdown widget.
                suffixIcon: _FontSelectorDropdown(
                  fontProvider: fontProvider,
                  getFontStyle: getFontStyle,
                  onFontChanged: (newFont) {
                    fontProvider.changeFont(newFont);
                    animationProvider.badgeAnimation(
                      controller.text,
                      Converters(),
                      animationProvider.isEffectActive(InvertLEDEffect()),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Font selector dropdown (UI-01) ──────────────────────────────────────────

/// Extracted from the original ~150-line inline DropdownButton.
/// TODO: Move to lib/view/widgets/font_selector_dropdown.dart
class _FontSelectorDropdown extends StatelessWidget {
  const _FontSelectorDropdown({
    required this.fontProvider,
    required this.getFontStyle,
    required this.onFontChanged,
  });

  final FontProvider fontProvider;
  final TextStyle Function(String) getFontStyle;
  final void Function(String?) onFontChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.280,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fontProvider.selectedFont,
          icon: const SizedBox.shrink(),
          iconEnabledColor: mdGrey400,
          dropdownColor: Colors.white,
          itemHeight: 48,
          isExpanded: true,
          style: TextStyle(color: mdGrey400, fontSize: 12.sp),
          hint: Text(
            'Font',
            style: TextStyle(fontSize: 12.sp, color: mdGrey400),
            overflow: TextOverflow.ellipsis,
          ),
          alignment: AlignmentDirectional.centerEnd,
          padding: EdgeInsets.zero,
          items: [
            _buildItem(null, 'Default'),
            ...fontProvider.availableFonts.map((f) => _buildItem(f, f)),
          ],
          selectedItemBuilder: (_) {
            final options = <String?>[null, ...fontProvider.availableFonts];
            return options
                .map(
                  (opt) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            opt ?? 'Default',
                            style:
                                TextStyle(color: mdGrey400, fontSize: 12.sp),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.arrow_drop_down,
                            size: 18, color: mdGrey400),
                      ],
                    ),
                  ),
                )
                .toList();
          },
          onChanged: onFontChanged,
          borderRadius: BorderRadius.circular(8.r),
          elevation: 2,
          isDense: true,
          menuMaxHeight: 300.h,
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildItem(String? value, String label) {
    final isActive = fontProvider.selectedFont == value;
    return DropdownMenuItem<String>(
      value: value,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? dividerColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: (value != null ? getFontStyle(value) : const TextStyle())
              .copyWith(
            fontSize: 12.sp,
            color: isActive ? colorAccent : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ── Emoji / vector picker panel ──────────────────────────────────────────────

class _EmojiPickerPanel extends StatelessWidget {
  const _EmojiPickerPanel({
    required this.isVisible,
    required this.scrollController,
  });

  final bool isVisible;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Visibility(
        visible: isVisible,
        child: Container(
          height: isVisible ? 170.h : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.grey[200],
          ),
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 4.0,
            radius: const Radius.circular(10),
            child: VectorGridView(controller: scrollController),
          ),
        ),
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _BadgeTabBar extends StatelessWidget {
  const _BadgeTabBar({required this.controller, required this.l10n});

  final TabController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        labelColor: Colors.black,
        unselectedLabelColor: mdGrey400,
        indicatorColor: colorPrimary,
        controller: controller,
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.pressed) ? dividerColor : null,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        tabs: [
          Tab(key: const ValueKey('tab_speed'), text: l10n.speedTitle),
          Tab(key: const ValueKey('tab_transition'), text: l10n.transitionTitle),
          Tab(key: const ValueKey('tab_effects'), text: l10n.effectsTitle),
          Tab(key: const ValueKey('tab_animation'), text: l10n.animation),
        ],
      ),
    );
  }
}

// ── Tab bar view ──────────────────────────────────────────────────────────────

class _BadgeTabBarView extends StatelessWidget {
  const _BadgeTabBarView({
    required this.tabController,
    required this.onDialPanDown,
    required this.onDialPanEnd,
  });

  final TabController tabController;
  final VoidCallback onDialPanDown;
  final VoidCallback onDialPanEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final availableHeight = 0.5 * ScreenUtil().screenHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 220.h,
            maxHeight: availableHeight,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: tabController,
              children: [
                GestureDetector(
                  onPanDown: (_) => onDialPanDown(),
                  onPanCancel: onDialPanEnd,
                  onPanEnd: (_) => onDialPanEnd(),
                  child: RadialDial(),
                ),
                const TransitionTab(),
                const EffectTab(),
                const AnimationTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Save + Transfer action buttons (UI-02) ────────────────────────────────────

/// Extracted from the original ~80-line inline Row in build().
/// TODO: Move to lib/view/widgets/badge_action_buttons.dart
class _BadgeActionButtons extends StatelessWidget {
  const _BadgeActionButtons({
    required this.l10n,
    required this.isSpecialAnimation,
    required this.onSave,
    required this.onTransfer,
  });

  final AppLocalizations l10n;
  final bool isSpecialAnimation;
  final VoidCallback onSave;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isSpecialAnimation) ...[
          Expanded(child: _ActionButton(label: l10n.saveButton, onTap: onSave)),
          SizedBox(width: 24.w),
        ],
        Expanded(
          child: _ActionButton(label: l10n.transferButton, onTap: onTransfer),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: mdGrey400,
        ),
        child: Text(label),
      ),
    );
  }
}
