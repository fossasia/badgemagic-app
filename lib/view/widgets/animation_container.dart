import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/view/widgets/special_animation_dialog.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';

class AniContainer extends StatefulWidget {
  final String? animation;
  final String animationName;
  final int index;
  final IconData? icon;

  const AniContainer({
    super.key,
    this.animation,
    required this.animationName,
    required this.index,
    this.icon,
  });

  @override
  State<AniContainer> createState() => _AniContainerState();
}

class _AniContainerState extends State<AniContainer> {
  BadgeAnimation? badgeAnimation;

  @override
  void initState() {
    badgeAnimation = animationMap[widget.index];
    super.initState();
  }

  String _getLocalizedAnimationName(String name, BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    switch (name) {
      case 'Left':
        return l10n.animationLeft;
      case 'Right':
        return l10n.animationRight;
      case 'Up':
        return l10n.animationUp;
      case 'Down':
        return l10n.animationDown;
      case 'Fixed':
        return l10n.animationFixed;
      case 'Snowflake':
        return l10n.animationSnowflake;
      case 'Picture':
        return l10n.animationPicture;
      case 'Laser':
        return l10n.animationLaser;
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    AnimationBadgeProvider animationCardState =
        Provider.of<AnimationBadgeProvider>(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      height: 65.h,
      child: GestureDetector(
        onTap: () async {
          final imageProvider =
              Provider.of<InlineImageProvider>(context, listen: false);
          final textController = imageProvider.getController();

          // Switch logic for Splitting (index 5) vs other animations
          final currentIndex =
              Provider.of<AnimationBadgeProvider>(context, listen: false)
                  .getAnimationIndex();
                  
          if (currentIndex == 5 && widget.index != 5) {
            // WE ARE LEAVING SPLITTING
            // Save the full multi-frame text
            imageProvider.savedMultiFrameText = textController.text;
            
            // Find which frame is active
            int activeIndex = 0;
            final parts = textController.text.split('\f');
            if (imageProvider.activeFrameController != null) {
              final activeText = imageProvider.activeFrameController!.text;
              activeIndex = parts.indexOf(activeText);
              if (activeIndex == -1) activeIndex = 0;
            }
            imageProvider.savedActiveFrameIndex = activeIndex;
            
            // Set the main controller to just the active frame's text
            if (parts.isNotEmpty) {
              textController.text = parts[activeIndex];
            }
            
            // Clear the active-frame reference
            imageProvider.activeFrameController = null;
          } else if (currentIndex != 5 && widget.index == 5) {
            // WE ARE ENTERING SPLITTING
            // Restore previous frames if they exist
            if (imageProvider.savedMultiFrameText != null) {
              List<String> parts =
                  imageProvider.savedMultiFrameText!.split('\f');
              int activeIndex = imageProvider.savedActiveFrameIndex ?? 0;
              
              // Replace the old active frame with any edits made in other modes
              if (activeIndex < parts.length) {
                parts[activeIndex] = textController.text;
              } else if (parts.isEmpty) {
                parts = [textController.text];
              }
              
              textController.text = parts.join('\f');
              
              // Clear saved state so we don't accidentally restore stale data later
              imageProvider.savedMultiFrameText = null;
              imageProvider.savedActiveFrameIndex = null;
            }
          }

          // Only show dialog for special animations (index >= 9)
          if (widget.index >= 9) {
            if (textController.text.trim().isNotEmpty) {
              final shouldSwitch = await showSpecialAnimationDialog(
                  context, textController.text.trim());
              if (shouldSwitch == true) {
                textController.clear();
                animationCardState.setAnimationMode(badgeAnimation);
                // Force preview update for special animations
                animationCardState.badgeAnimation('', Converters(), false);
              }
              return;
            }
          }
          animationCardState.setAnimationMode(badgeAnimation);
        },
        child: Card(
          surfaceTintColor: Colors.white,
          color: animationCardState.isAnimationActive(badgeAnimation)
              ? colorPrimaryDark
              : drawerHeaderTitle,
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 36,
                        color:
                            animationCardState.isAnimationActive(badgeAnimation)
                                ? Colors.white
                                : const Color.fromARGB(255, 117, 117, 117),
                      )
                    : (widget.animation != null
                        ? Image.asset(
                            widget.animation!,
                            fit: BoxFit.fill,
                            color: animationCardState
                                    .isAnimationActive(badgeAnimation)
                                ? Colors.white
                                : null,
                            colorBlendMode: animationCardState
                                    .isAnimationActive(badgeAnimation)
                                ? BlendMode.srcIn
                                : null,
                          )
                        : SizedBox.shrink()),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  _getLocalizedAnimationName(widget.animationName, context),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: animationCardState.isAnimationActive(badgeAnimation)
                        ? Colors.white
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
