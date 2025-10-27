import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_animation.dart';
import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/saved_badge_listview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class SaveBadgeScreen extends StatefulWidget {
  const SaveBadgeScreen({super.key});

  @override
  State<SaveBadgeScreen> createState() => _SaveBadgeScreenState();
}

class _SaveBadgeScreenState extends State<SaveBadgeScreen> {
  List<MapEntry<String, Map<String, dynamic>>> badgeData = [];
  InlineImageProvider imageProvider = GetIt.instance<InlineImageProvider>();
  ToastUtils toastUtils = ToastUtils();
  FileHelper fileHelper = FileHelper();
  SavedBadgeProvider savedBadgeProvider = SavedBadgeProvider();
  AnimationBadgeProvider animationBadgeProvider = AnimationBadgeProvider();

  @override
  void initState() {
    _setOrientation();
    super.initState();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    animationBadgeProvider.stopAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    BadgeMessageProvider badgeMessageProvider = BadgeMessageProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SavedBadgeProvider>.value(
          value: savedBadgeProvider,
        ),
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (context) => animationBadgeProvider,
        ),
        ChangeNotifierProvider<BadgeSlotProvider>(
          create: (context) => BadgeSlotProvider(),
        ),
      ],
      child: CommonScaffold(
        title: l10n.savedBadges,
        index: 2,
        actions: [
          TextButton(
            onPressed: () async {
              final value = await fileHelper.importBadgeData(context);
              if (value) {
                logger.d('value: $value');
                toastUtils.showToast(l10n.badgeImportedSuccessfully);
                await fileHelper.getBadgeDataFiles();
                setState(() {});
              }
            },
            child: Text(
              l10n.import,
              style: const TextStyle(color: drawerHeaderTitle),
            ),
          ),
          Consumer<BadgeSlotProvider>(
            builder: (context, selectionProvider, _) {
              if (selectionProvider.selectedBadges.isEmpty) {
                return SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: l10n.deleteSelected,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteSelectedBadges),
                      content: Text(l10n.deleteBadgesConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final provider = Provider.of<InlineImageProvider>(context,
                        listen: false);
                    final selectedBadges =
                        selectionProvider.selectedBadges.toList();
                    for (final badgeKey in selectedBadges) {
                      await FileHelper().deleteFile(badgeKey);
                      provider.savedBadgeCache
                          .removeWhere((entry) => entry.key == badgeKey);
                    }
                    selectionProvider.clearSelections();
                    setState(() {});
                    ToastUtils().showToast(l10n.badgesDeletedSuccessfully);
                  }
                },
              );
            },
          ),
        ],
        body: Consumer<InlineImageProvider>(
          builder: (context, provider, child) {
            if (provider.savedBadgeCache.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 50.0.w),
                      child: SvgPicture.asset(
                        'assets/icons/empty_badge.svg',
                        height: 200.h,
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Text(
                      'No saved badges !',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.sp,
                      ),
                    ),
                    Text(
                      'Looks like there are no saved badges yet.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      AnimationBadge(),
                      Expanded(
                        child: Selector<BadgeSlotProvider, bool>(
                            selector: (context, selectionProvider) =>
                                selectionProvider.selectedBadges.isNotEmpty,
                            builder: (context, isTransferEnabled, _) {
                              return BadgeListView(
                                isTransferEnabled: isTransferEnabled,
                                futureBadges:
                                    Future.value(provider.savedBadgeCache),
                                refreshBadgesCallback: (value) {
                                  provider.savedBadgeCache.remove(value);
                                  setState(() {});
                                  return Future.value();
                                },
                              );
                            }),
                      ),
                    ],
                  ),
                  Consumer<BadgeSlotProvider>(
                    builder: (context, selectionProvider, _) {
                      return Positioned(
                        bottom: 10.h,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: selectionProvider.selectedBadges.isNotEmpty
                              ? 1.0
                              : 0.0,
                          child: Container(
                            width: 300.w,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: TextButton(
                              onPressed: selectionProvider
                                      .selectedBadges.isNotEmpty
                                  ? () async {
                                      // Get all badges sorted by visual order
                                      final allBadges =
                                          provider.savedBadgeCache.toList();

                                      // Sort by visual order if available
                                      allBadges.sort((a, b) {
                                        final visualA = selectionProvider
                                            .getVisualOrder(a.key);
                                        final visualB = selectionProvider
                                            .getVisualOrder(b.key);

                                        if (visualA != null &&
                                            visualB != null) {
                                          return visualA.compareTo(visualB);
                                        }
                                        if (visualA != null) return -1;
                                        if (visualB != null) return 1;
                                        return 0; // Both null, keep original order
                                      });

                                      // Take first 8 badges
                                      final firstEightBadges =
                                          allBadges.take(8).toList();

                                      List<Message> badgeDataList = [];

                                      // For each of the 8 positions
                                      for (var badgeEntry in firstEightBadges) {
                                        final isSelected = selectionProvider
                                            .isSelected(badgeEntry.key);

                                        if (isSelected) {
                                          // Badge is selected, use its data
                                          final message = Message.fromJson(
                                              badgeEntry.value['messages'][0]);
                                          badgeDataList.add(message);
                                        } else {
                                          // Badge is not selected, send empty
                                          badgeDataList.add(Message(text: []));
                                        }
                                      }

                                      // Fill remaining slots if less than 8 badges
                                      while (badgeDataList.length < 8) {
                                        badgeDataList.add(Message(text: []));
                                      }

                                      if (badgeDataList
                                              .where(
                                                  (msg) => msg.text.isNotEmpty)
                                              .length >
                                          1) {
                                        animationBadgeProvider
                                            .setAnimationMode(AniAnimation());
                                      } else {
                                        animationBadgeProvider
                                            .setAnimationMode(FixedAnimation());
                                      }
                                      final fullText = badgeDataList
                                          .map((m) => m.text.join())
                                          .join(" ");
                                      animationBadgeProvider.badgeAnimation(
                                        fullText,
                                        Converters(),
                                        false,
                                      );
                                      final data =
                                          Data(messages: badgeDataList);
                                      badgeMessageProvider.checkAndTransfer(
                                          null,
                                          null,
                                          null,
                                          null,
                                          null,
                                          null,
                                          data.toJson(),
                                          true,
                                          context);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: Text(
                                l10n.transferButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
        key: const Key(savedBadgeScreen),
      ),
    );
  }
}
