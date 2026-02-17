import 'package:badgemagic/view/widgets/save_badge_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';

class BadgeListView extends StatefulWidget {
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
  State<BadgeListView> createState() => _BadgeListViewState();
}

class _BadgeListViewState extends State<BadgeListView> {
  bool isAscending = true;

  void toggleSort() {
    setState(() {
      isAscending = !isAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
      future: widget.futureBadges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MapEntry<String, Map<String, dynamic>>> savedBadges = snapshot
            .data!
            .where((entry) => entry.key != 'badge_original_texts.json')
            .toList();

        // 🔥 SORTING LOGIC
        savedBadges.sort((a, b) {
          return isAscending
              ? a.key.compareTo(b.key)
              : b.key.compareTo(a.key);
        });

        return Column(
          children: [
            // 🔼 Sort Button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  isAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: toggleSort,
              ),
            ),

            Expanded(
              child: Consumer<BadgeSlotProvider>(
                builder: (context, slotProvider, _) => Padding(
                  padding: EdgeInsets.only(
                      bottom: widget.isTransferEnabled ? 75.0 : 0),
                  child: ListView.builder(
                    itemCount: savedBadges.length,
                    itemBuilder: (context, index) {
                      final badgeKey = savedBadges[index].key;
                      final isSelected =
                          slotProvider.isSelected(badgeKey);

                      return SaveBadgeCard(
                        badgeData: savedBadges[index],
                        refreshBadgesCallback:
                            widget.refreshBadgesCallback,
                        isSelected: isSelected,
                        onLongPress: () {
                          slotProvider.toggleSelection(badgeKey);
                          if (widget.onSelectionChanged != null) {
                            widget.onSelectionChanged!();
                          }
                        },
                        onTap: () {
                          if (slotProvider.selectedBadges
                              .isNotEmpty) {
                            slotProvider.toggleSelection(badgeKey);
                            if (widget.onSelectionChanged != null) {
                              widget.onSelectionChanged!();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
