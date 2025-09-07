import 'dart:convert';

import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class SavedFramesScreen extends StatefulWidget {
  const SavedFramesScreen({super.key});

  @override
  State<SavedFramesScreen> createState() => _SavedFramesScreenState();
}

class _SavedFramesScreenState extends State<SavedFramesScreen> {
  List<MapEntry<String, List<List<List<int>>>>> _saved = [];

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && f.path.contains('frames_'))
        .toList();
    List<MapEntry<String, List<List<List<int>>>>> items = [];
    for (final f in files) {
      try {
        final content = await f.readAsString();
        final data = jsonDecode(content);
        List<List<List<int>>> frames;
        if (data is List) {
          // backward compatibility (no speed)
          frames = (data)
              .map((frame) => (frame as List<dynamic>)
                  .map((row) => (row as List<dynamic>).cast<int>())
                  .toList())
              .toList();
        } else {
          frames = (data['frames'] as List<dynamic>)
              .map((frame) => (frame as List<dynamic>)
                  .map((row) => (row as List<dynamic>).cast<int>())
                  .toList())
              .toList();
        }
        items.add(MapEntry(f.uri.pathSegments.last, frames));
      } catch (_) {}
    }
    setState(() => _saved = items);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnimationBadgeProvider(),
      child: CommonScaffold(
        index: 4,
        title: 'Saved Frame Animation',
        body: Column(
          children: [
            const SizedBox(height: 8),
            const AnimationBadge(),
            Expanded(
              child: ListView.builder(
                itemCount: _saved.length,
                itemBuilder: (context, index) {
                  final item = _saved[index];
                  return Container(
                    width: 370.w,
                    padding: EdgeInsets.all(6.dg),
                    margin: EdgeInsets.all(10.dg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.dg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Text(
                                  item.key
                                      .replaceAll('frames_', '')
                                      .replaceAll('.json', ''),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () async {
                                    final provider =
                                        context.read<AnimationBadgeProvider>();
                                    final frames = item.value;
                                    final height = frames.first.length;
                                    final width = frames.first.first.length;
                                    final stitched = List.generate(
                                        height,
                                        (_) => List<bool>.filled(
                                            width * frames.length, false));
                                    for (int fi = 0; fi < frames.length; fi++) {
                                      for (int r = 0; r < height; r++) {
                                        for (int c = 0; c < width; c++) {
                                          stitched[r][fi * width + c] =
                                              frames[fi][r][c] == 1;
                                        }
                                      }
                                    }
                                    provider.setNewGrid(stitched);
                                    // read speed if present
                                    int playSpeed = 1;
                                    try {
                                      final dir =
                                          await getApplicationDocumentsDirectory();
                                      final path = '${dir.path}/${item.key}';
                                      final jsonStr =
                                          await File(path).readAsString();
                                      final parsed = jsonDecode(jsonStr);
                                      if (parsed is Map &&
                                          parsed['speed'] is int) {
                                        playSpeed = parsed['speed'];
                                      }
                                    } catch (_) {}
                                    provider.calculateDuration(playSpeed);
                                    provider.setAnimationMode(animationMap[0]);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final dir =
                                        await getApplicationDocumentsDirectory();
                                    final path = '${dir.path}/${item.key}';
                                    final f = File(path);
                                    if (await f.exists()) await f.delete();
                                    await _load();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
