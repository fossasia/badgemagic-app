import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_animation.dart';
import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';

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

import '../providers/badge_slot_provider..dart';

class SaveBadgeScreen extends StatefulWidget {
  const SaveBadgeScreen({super.key});

  @override
  State<SaveBadgeScreen> createState() => _SaveBadgeScreenState();
}

class _SaveBadgeScreenState extends State<SaveBadgeScreen> {
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
          Consumer<BadgeSlotProvider>(builder: (context, slots, _) {
            final hasItems = slots.orderedBadges.isNotEmpty;
            return TextButton(
              onPressed: hasItems
                  ? () {
                      final badgesToTransfer =
                          slots.orderedBadges.take(8).toList();

                      List<Map<String, dynamic>> messagesList = [];
                      List<String> combinedHexText = [];

                      for (var entry in badgesToTransfer) {
                        final rawMessage = Map<String, dynamic>.from(
                            entry.value['messages'][0]);
                        messagesList.add(rawMessage);
                        if (rawMessage['text'] != null) {
                          combinedHexText
                              .add((rawMessage['text'] as List).join());
                        }
                      }

                      if (messagesList.isNotEmpty) {
                        Map<String, dynamic> blankTemplate =
                            Map.from(messagesList.last);
                        blankTemplate['text'] = <String>[];
                        while (messagesList.length < 8) {
                          messagesList.add(Map.from(blankTemplate));
                        }
                      }

                      if (combinedHexText.length > 1) {
                        animationBadgeProvider.setAnimationMode(AniAnimation());
                      } else {
                        animationBadgeProvider
                            .setAnimationMode(FixedAnimation());
                      }

                      final fullText = combinedHexText.join(" ");
                      animationBadgeProvider.badgeAnimation(
                        fullText,
                        Converters(),
                        false,
                      );

                      final transferData = {'messages': messagesList};

                      badgeMessageProvider.checkAndTransfer(null, null, null,
                          null, null, null, transferData, true, context);
                    }
                  : null,
              child: Text(
                'Transfer All',
                style: TextStyle(
                  color: hasItems ? drawerHeaderTitle : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            );
          }),
          Builder(builder: (innerContext) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: drawerHeaderTitle),
              onSelected: (String result) async {
                if (result == 'import') {
                  final value = await fileHelper.importBadgeData(context);
                  if (value) {
                    toastUtils.showToast(l10n.badgeImportedSuccessfully);
                    await fileHelper.getBadgeDataFiles();
                    setState(() {});
                  }
                } else if (result == 'delete_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete All Badges"),
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
                    if (!context.mounted) return;
                    final imageProvider = Provider.of<InlineImageProvider>(
                        innerContext,
                        listen: false);
                    final slotProvider = Provider.of<BadgeSlotProvider>(
                        innerContext,
                        listen: false);

                    final badgesToDelete = List.from(imageProvider
                        .savedBadgeCache
                        .where(
                            (entry) => entry.key != 'badge_original_texts.json')
                        .toList());

                    for (var entry in badgesToDelete) {
                      try {
                        FileHelper().deleteFile(entry.key);
                        await Future.delayed(const Duration(milliseconds: 50));
                      } catch (e) {
                        debugPrint("Failed to delete ${entry.key}: $e");
                      }
                    }

                    slotProvider.clearAll();
                    imageProvider.savedBadgeCache.clear();
                    await fileHelper.getBadgeDataFiles();

                    toastUtils.showToast("All badges deleted successfully");

                    if (mounted) {
                      setState(() {});
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'import',
                  child: Text(l10n.import),
                ),
                const PopupMenuItem<String>(
                  value: 'delete_all',
                  child:
                      Text('Delete All', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          }),
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
                    SizedBox(height: 20.h),
                    Text(
                      'No saved badges !',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final slotProvider =
                  Provider.of<BadgeSlotProvider>(context, listen: false);
              slotProvider.initialize(provider.savedBadgeCache);

              return Column(
                children: [
                  AnimationBadge(),
                  Expanded(
                    child: BadgeListView(
                      refreshBadgesCallback: (value) {
                        provider.savedBadgeCache
                            .removeWhere((entry) => entry.key == value.key);
                        setState(() {});
                        return Future.value();
                      },
                    ),
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
