import 'package:badgemagic/view/widgets/save_badge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  // ignore: unused_field
  String? _draggingItem;
  // ignore: unused_field
  int? _hoveredIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildDragFeedback(String badgeKey, BadgeSlotProvider slotProvider) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12.dg),
      shadowColor: colorPrimary.withOpacity(0.5),
      child: Container(
        width: 360.w,
        padding: EdgeInsets.all(16.dg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, colorPrimary.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.dg),
          border: Border.all(color: colorPrimary, width: 3),
          boxShadow: [
            BoxShadow(
              color: colorPrimary.withOpacity(0.3),
              spreadRadius: 4,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.dg),
              decoration: BoxDecoration(
                color: colorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorPrimary.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.drag_indicator,
                color: colorPrimary,
                size: 24,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeKey.substring(0, badgeKey.length - 5),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimary.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Slot ${slotProvider.getSlotForBadge(badgeKey) ?? '?'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details, BuildContext context) {
    // Use Scrollable.ensureVisible for smooth auto-scrolling
    final RenderBox? renderBox =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !_scrollController.hasClients) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final viewportHeight = renderBox.size.height;

    const threshold = 80.0;

    // Check if near edges
    if (localPosition.dy < threshold && _scrollController.offset > 0) {
      // Scroll up
      final targetOffset = (_scrollController.offset - 10).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(targetOffset);
    } else if (localPosition.dy > viewportHeight - threshold &&
        _scrollController.offset < _scrollController.position.maxScrollExtent) {
      // Scroll down
      final targetOffset = (_scrollController.offset + 10).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
      future: widget.futureBadges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MapEntry<String, Map<String, dynamic>>> allBadges = snapshot.data!
            .where((entry) => entry.key != 'badge_original_texts.json')
            .toList();

        return Consumer<BadgeSlotProvider>(
          builder: (context, slotProvider, _) {
            // Sort badges: selected ones first (by slot order), then unselected
            final selectedBadges = slotProvider.getSelectionsOrderedBySlot();
            final selectedBadgeKeys = selectedBadges.toSet();

            final selectedBadgeEntries =
                <MapEntry<String, Map<String, dynamic>>>[];
            final unselectedBadgeEntries =
                <MapEntry<String, Map<String, dynamic>>>[];

            for (final badge in allBadges) {
              if (selectedBadgeKeys.contains(badge.key)) {
                selectedBadgeEntries.add(badge);
              } else {
                unselectedBadgeEntries.add(badge);
              }
            }

            // Sort selected badges by their slot number
            selectedBadgeEntries.sort((a, b) {
              final slotA = slotProvider.getSlotForBadge(a.key) ?? 999;
              final slotB = slotProvider.getSlotForBadge(b.key) ?? 999;
              return slotA.compareTo(slotB);
            });

            final sortedBadges = [
              ...selectedBadgeEntries,
              ...unselectedBadgeEntries
            ];

            return Padding(
              padding:
                  EdgeInsets.only(bottom: widget.isTransferEnabled ? 75.0 : 0),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // This enables automatic scroll notifications during drag
                  return false;
                },
                child: ListView.builder(
                  key: _listKey,
                  controller: _scrollController,
                  itemCount: sortedBadges.length,
                  // Enable auto-scroll behavior
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final badgeData = sortedBadges[index];
                    final badgeKey = badgeData.key;
                    final isSelected = slotProvider.isSelected(badgeKey);
                    final isInSelectedSection =
                        index < selectedBadgeEntries.length;

                    if (isInSelectedSection && isSelected) {
                      // Make selected badges draggable
                      return Container(
                        key: ValueKey(badgeKey),
                        margin: EdgeInsets.symmetric(
                            vertical: 4.h, horizontal: 8.w),
                        child: LongPressDraggable<String>(
                          data: badgeKey,
                          hapticFeedbackOnStart: true,
                          delay: const Duration(milliseconds: 200),
                          // Use pointer drag anchor for better control
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          onDragStarted: () {
                            setState(() {
                              _draggingItem = badgeKey;
                            });
                            HapticFeedback.mediumImpact();
                          },
                          onDragUpdate: (details) {
                            _handleDragUpdate(details, context);
                          },
                          onDragEnd: (details) {
                            setState(() {
                              _draggingItem = null;
                              _hoveredIndex = null;
                            });
                          },
                          onDraggableCanceled: (velocity, offset) {
                            setState(() {
                              _draggingItem = null;
                              _hoveredIndex = null;
                            });
                          },
                          feedback: _buildDragFeedback(badgeKey, slotProvider),
                          childWhenDragging: AnimatedOpacity(
                            opacity: 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.dg),
                                border: Border.all(
                                  color: colorPrimary.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: SaveBadgeCard(
                                badgeData: badgeData,
                                refreshBadgesCallback:
                                    widget.refreshBadgesCallback,
                                isSelected: isSelected,
                                showDragHandle: true,
                                onLongPress: () {
                                  slotProvider.toggleSelection(badgeKey);
                                  if (widget.onSelectionChanged != null) {
                                    widget.onSelectionChanged!();
                                  }
                                },
                                onTap: () {
                                  if (slotProvider.selectedBadges.isNotEmpty) {
                                    slotProvider.toggleSelection(badgeKey);
                                    if (widget.onSelectionChanged != null) {
                                      widget.onSelectionChanged!();
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (details) {
                              return details.data != badgeKey &&
                                  slotProvider.isSelected(details.data);
                            },
                            onAcceptWithDetails: (details) {
                              slotProvider.reorderSlots(details.data, badgeKey);
                              if (widget.onSelectionChanged != null) {
                                widget.onSelectionChanged!();
                              }
                              HapticFeedback.lightImpact();
                            },
                            onMove: (details) {
                              setState(() {
                                _hoveredIndex = index;
                              });
                            },
                            onLeave: (data) {
                              setState(() {
                                _hoveredIndex = null;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isHovering = candidateData.isNotEmpty;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                transform: Matrix4.identity()
                                  ..scale(isHovering ? 1.02 : 1.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.dg),
                                  border: isHovering
                                      ? Border.all(
                                          color: colorPrimary, width: 3)
                                      : null,
                                  boxShadow: isHovering
                                      ? [
                                          BoxShadow(
                                            color:
                                                colorPrimary.withOpacity(0.4),
                                            spreadRadius: 3,
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: SaveBadgeCard(
                                  badgeData: badgeData,
                                  refreshBadgesCallback:
                                      widget.refreshBadgesCallback,
                                  isSelected: isSelected,
                                  showDragHandle: true,
                                  onLongPress: () {
                                    slotProvider.toggleSelection(badgeKey);
                                    if (widget.onSelectionChanged != null) {
                                      widget.onSelectionChanged!();
                                    }
                                  },
                                  onTap: () {
                                    if (slotProvider
                                        .selectedBadges.isNotEmpty) {
                                      slotProvider.toggleSelection(badgeKey);
                                      if (widget.onSelectionChanged != null) {
                                        widget.onSelectionChanged!();
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      // Non-selected badges or unselected section
                      return Container(
                        key: ValueKey(badgeKey),
                        margin: EdgeInsets.symmetric(
                            vertical: 4.h, horizontal: 8.w),
                        child: SaveBadgeCard(
                          badgeData: badgeData,
                          refreshBadgesCallback: widget.refreshBadgesCallback,
                          isSelected: isSelected,
                          showDragHandle: false,
                          onLongPress: () {
                            slotProvider.toggleSelection(badgeKey);
                            if (widget.onSelectionChanged != null) {
                              widget.onSelectionChanged!();
                            }
                          },
                          onTap: () {
                            if (slotProvider.selectedBadges.isNotEmpty) {
                              slotProvider.toggleSelection(badgeKey);
                              if (widget.onSelectionChanged != null) {
                                widget.onSelectionChanged!();
                              }
                            }
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
