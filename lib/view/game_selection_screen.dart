import 'package:flutter/material.dart';
import 'package:badgemagic/view/gamescreen.dart';
import 'package:badgemagic/view/tetris_game_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose your game:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Snake Game Button
                  _GameChoiceButton(
                    icon: Icons.android,
                    label: 'Snake Game',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 32),
                  // Tetris Game Button
                  _GameChoiceButton(
                    icon: Icons.extension,
                    label: 'Tetris Game',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TetrisGameScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GameChoiceButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
