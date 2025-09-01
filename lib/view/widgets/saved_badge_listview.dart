import 'package:badgemagic/view/widgets/save_badge_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';

class BadgeListView extends StatelessWidget {
  final Future<List<MapEntry<String, Map<String, dynamic>>>> futureBadges;
  final bool isTransferEnabled;
  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback;
  final void Function()? onSelectionChanged;

  const BadgeListView({
    super.key,
    required this.isTransferEnabled,
    required this.futureBadges,
    required this.refreshBadgesCallback,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
      future: futureBadges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          List<MapEntry<String, Map<String, dynamic>>> savedBadges = snapshot
              .data!
              .where((entry) => entry.key != 'badge_original_texts.json')
              .toList();
          return Consumer<BadgeSlotProvider>(
            builder: (context, slotProvider, _) => Padding(
              padding: EdgeInsets.only(bottom: isTransferEnabled ? 75.0 : 0),
              child: ListView.builder(
                itemCount: savedBadges.length,
                itemBuilder: (context, index) {
                  final badgeKey = savedBadges[index].key;
                  final isSelected = slotProvider.isSelected(badgeKey);
                  return SaveBadgeCard(
                    badgeData: savedBadges[index],
                    refreshBadgesCallback: refreshBadgesCallback,
                    isSelected: isSelected,
                    onLongPress: () {
                      slotProvider.toggleSelection(badgeKey);
                      if (onSelectionChanged != null) onSelectionChanged!();
                    },
                    onTap: () {
                      if (slotProvider.selectedBadges.isNotEmpty) {
                        slotProvider.toggleSelection(badgeKey);
                        if (onSelectionChanged != null) onSelectionChanged!();
                      }
                    },
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
