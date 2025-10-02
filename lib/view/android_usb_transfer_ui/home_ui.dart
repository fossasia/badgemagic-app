// android_home_ui.dart
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/providers/transfer_provider.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/view/widgets/transfer_method_tray.dart';

class AndroidHomeUI {
  static Widget buildAndroidUI({
    required BuildContext context,
    required AppLocalizations l10n,
    required InlineImageProvider inlineImageProvider,
    required AnimationBadgeProvider animationProvider,
    required SpeedDialProvider speedDialProvider,
    required BadgeMessageProvider badgeData,
    required bool isPrefixIconClicked,
    required bool isDialInteracting,
    required TabController tabController,
    required TextEditingController inlineImageController,
    required VoidCallback onPrefixIconPressed,
    required ValueChanged<bool> onDialInteractingChanged,
    required Widget vectorGridView,
    required Widget animationBadge,
    required Widget radialDial,
    required Widget transitionTab,
    required Widget effectTab,
    required Widget animationTab,
    required VoidCallback onSavePressed, // Add this callback
  }) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: isDialInteracting
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              animationBadge,
              // Reuse the existing container and text field from homescreen
              _buildTextFieldSection(
                context: context,
                l10n: l10n,
                inlineImageProvider: inlineImageProvider,
                inlineImageController: inlineImageController,
                isPrefixIconClicked: isPrefixIconClicked,
                onPrefixIconPressed: onPrefixIconPressed,
                animationProvider: animationProvider,
              ),
              Visibility(
                visible: isPrefixIconClicked,
                child: Container(
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: vectorGridView,
                ),
              ),
              // Reuse the existing tab bar
              _buildTabBar(
                context: context,
                l10n: l10n,
                tabController: tabController,
              ),
              SizedBox(
                height: 350,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: tabController,
                  children: [
                    GestureDetector(
                      onPanDown: (_) => onDialInteractingChanged(true),
                      onPanCancel: () => onDialInteractingChanged(false),
                      onPanEnd: (_) => onDialInteractingChanged(false),
                      child: radialDial,
                    ),
                    transitionTab,
                    effectTab,
                    animationTab,
                  ],
                ),
              ),
              // Android-specific centered buttons
              _buildAndroidButtons(
                context: context,
                l10n: l10n,
                animationProvider: animationProvider,
                inlineImageController: inlineImageController,
                badgeData: badgeData,
                inlineImageProvider: inlineImageProvider,
                speedDialProvider: speedDialProvider,
                onSavePressed: onSavePressed, // Pass the callback
              ),
              SizedBox(height: 20),
            ],
          ),
        ),

        // Transfer Method Tray Overlay
        Consumer<TransferProvider>(
          builder: (context, transferProvider, _) {
            if (transferProvider.showTray) {
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    transferProvider.closeTray();
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Transfer Method Tray - This was missing!
        Consumer<TransferProvider>(
          builder: (context, transferProvider, _) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              bottom: transferProvider.showTray ? 0 : -300,
              left: 0,
              right: 0,
              child: TransferMethodTray(
                onMethodSelected: (method) async {
                  print("🎯 Tray method selected: $method");
                  transferProvider.selectMethod(method);
                  await AndroidHomeUI.handleTransfer(
                    context: context,
                    method: method,
                    animationProvider: animationProvider,
                    badgeData: badgeData,
                    inlineImageProvider: inlineImageProvider,
                    speedDialProvider: speedDialProvider,
                  );
                },
                onCancel: () {
                  print("🎯 Tray cancel pressed");
                  transferProvider.closeTray();
                },
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget _buildTextFieldSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required InlineImageProvider inlineImageProvider,
    required TextEditingController inlineImageController,
    required bool isPrefixIconClicked,
    required VoidCallback onPrefixIconPressed,
    required AnimationBadgeProvider animationProvider,
  }) {
    // This would reuse the exact same text field implementation from homescreen
    // You can extract this from your existing build method
    return Container(
      margin: EdgeInsets.all(15),
      child: Material(
        color: Colors.grey[300], // Use your actual color
        borderRadius: BorderRadius.circular(10),
        elevation: 4,
        child: TextField(
          controller: inlineImageController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: IconButton(
              onPressed: onPrefixIconPressed,
              icon: const Icon(Icons.tag_faces_outlined),
            ),
            hintText: 'Enter message',
          ),
        ),
      ),
    );
  }

  static Widget _buildTabBar({
    required BuildContext context,
    required AppLocalizations l10n,
    required TabController tabController,
  }) {
    return TabBar(
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      labelColor: const Color.fromARGB(255, 12, 12, 12),
      unselectedLabelColor: const Color.fromARGB(255, 146, 121, 121),
      indicatorColor: Colors.blue, // Use your actual color
      controller: tabController,
      tabs: [
        Tab(key: const ValueKey('tab_speed'), text: l10n.speedTitle),
        Tab(key: const ValueKey('tab_transition'), text: l10n.transitionTitle),
        Tab(key: const ValueKey('tab_effects'), text: l10n.effectsTitle),
        Tab(key: const ValueKey('tab_animation'), text: l10n.animation),
      ],
    );
  }

  static Widget _buildAndroidButtons({
    required BuildContext context,
    required AppLocalizations l10n,
    required AnimationBadgeProvider animationProvider,
    required TextEditingController inlineImageController,
    required BadgeMessageProvider badgeData,
    required InlineImageProvider inlineImageProvider,
    required SpeedDialProvider speedDialProvider,
    required VoidCallback onSavePressed, // Add this parameter
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer<AnimationBadgeProvider>(
          builder: (context, animationProvider, _) {
            final isSpecial = animationProvider.isSpecialAnimationSelected();

            if (isSpecial) {
              return GestureDetector(
                onTap: () async {
                  print("🔄 Transfer button tapped");
                  final transferProvider =
                      Provider.of<TransferProvider>(context, listen: false);
                  print("Before openTray: ${transferProvider.showTray}");
                  transferProvider.openTray();
                  print("After openTray: ${transferProvider.showTray}");
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 33, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey[400],
                  ),
                  child: Text(l10n.transferButton),
                ),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Save button - now uses the callback from homescreen
                  GestureDetector(
                    onTap: onSavePressed, // Use the callback directly
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 33, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey[400],
                      ),
                      child: Text(l10n.saveButton),
                    ),
                  ),
                  SizedBox(width: 40),
                  // Transfer button
                  GestureDetector(
                    onTap: () {
                      print("🔄 Transfer button tapped");
                      final transferProvider =
                          Provider.of<TransferProvider>(context, listen: false);
                      print("Before openTray: ${transferProvider.showTray}");
                      transferProvider.openTray();
                      print("After openTray: ${transferProvider.showTray}");
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 33, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey[400],
                      ),
                      child: Text(l10n.transferButton),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  static Future<void> handleTransfer({
    required BuildContext context,
    required ConnectionType method,
    required AnimationBadgeProvider animationProvider,
    required BadgeMessageProvider badgeData,
    required InlineImageProvider inlineImageProvider,
    required SpeedDialProvider speedDialProvider,
  }) async {
    try {
      await animationProvider.handleAnimationTransfer(
        badgeData: badgeData,
        inlineImageProvider: inlineImageProvider,
        speedDialProvider: speedDialProvider,
        flash: animationProvider.isEffectActive(FlashEffect()),
        marquee: animationProvider.isEffectActive(MarqueeEffect()),
        invert: animationProvider.isEffectActive(InvertLEDEffect()),
        context: context,
        connectionType: method,
      );
    } catch (e) {
      ToastUtils().showToast("Transfer failed: ${e.toString()}");
    } finally {
      final transferProvider =
          Provider.of<TransferProvider>(context, listen: false);
      transferProvider.reset();
    }
  }
}
