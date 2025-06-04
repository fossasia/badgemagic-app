import 'package:badgemagic/view/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tetris_game_provider.dart';
import '../constants.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';

class TetrisGameScreen extends StatelessWidget {
  const TetrisGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TetrisGameProvider>(
      create: (_) => TetrisGameProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tetris Game'),
          backgroundColor: colorPrimary,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<TetrisGameProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 12),
                        Text('Score: ${provider.score}',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        // Badge display for Tetris (16x44)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: AspectRatio(
                            aspectRatio: 44 / 16, // 44 columns, 16 rows
                            child: CustomPaint(
                              painter: BadgePaint(
                                grid: provider.displayGrid
                                    .map((row) =>
                                        row.map((cell) => cell != 0).toList())
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        if (provider.isGameOver)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text('Game Over',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: provider.restart,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: colorPrimary),
                                  child: Text('Restart',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        if (!provider.isGameOver)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _TetrisControlButton(
                                  icon: Icons.arrow_left,
                                  onTap: provider.moveLeft,
                                ),
                                SizedBox(width: 16),
                                _TetrisControlButton(
                                  icon: Icons.rotate_right,
                                  onTap: provider.rotate,
                                ),
                                SizedBox(width: 16),
                                _TetrisControlButton(
                                  icon: Icons.arrow_right,
                                  onTap: provider.moveRight,
                                ),
                                SizedBox(width: 16),
                                _TetrisControlButton(
                                  icon: Icons.arrow_downward,
                                  onTap: provider.drop,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              // Bottom navigation bar
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom navigation bar for Tetris game
  Widget _buildBottomNavigation(BuildContext context) {
    final bool isBadgeSelected = false;
    final bool isGameSelected = true;
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
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(isBadgeSelected, 'Badge', Icons.badge, context),
            _buildNavButton(isGameSelected, 'Game', Icons.gamepad, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
      bool isSelected, String label, IconData icon, BuildContext context) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? colorPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorPrimary : Colors.grey,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorPrimary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TetrisControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TetrisControlButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, size: 32, color: Colors.black87),
        ),
      ),
    );
  }
}
