import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/snake_game_provider.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Snake game provider
  final SnakeGameProvider _gameProvider = SnakeGameProvider();

  @override
  void initState() {
    super.initState();
    _gameProvider.initGame();
    _gameProvider.addListener(_checkGameOver);

    // Start the game after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _gameProvider.startGame();
    });
  }

  void _checkGameOver() {
    // Show game over dialog when game is over
    if (_gameProvider.isGameOver) {
      // Delay dialog slightly to allow UI to update
      Future.delayed(Duration(milliseconds: 300), () {
        _showGameOverDialog(_gameProvider.score);
      });
    }
  }

  void _showGameOverDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Game Over!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 50.sp,
                color: Colors.orange,
              ),
              SizedBox(height: 16.h),
              Text(
                'Your Score: $score',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Snake touched its body!',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameProvider.initGame();
                _gameProvider.startGame();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: colorPrimary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up when the screen is disposed
    _gameProvider.removeListener(_checkGameOver);
    _gameProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SnakeGameProvider>.value(
      value: _gameProvider,
      child: CommonScaffold(
        index: 0, // Same index as home to highlight the same drawer item
        title: 'Snake Game',
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Game score and speed display
                Consumer<SnakeGameProvider>(
                  builder: (context, gameProvider, child) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Score display
                          Text(
                            'Score: ${gameProvider.score}',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: colorPrimary,
                            ),
                          ),

                          // Speed display
                          Row(
                            children: [
                              Text(
                                'Speed: ',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: colorPrimary,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '${gameProvider.speedPercentage}%',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Snake game badge display
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: AspectRatio(
                    aspectRatio: 3.2,
                    child: Consumer<SnakeGameProvider>(
                      builder: (context, gameProvider, child) {
                        return CustomPaint(
                          painter: BadgePaint(grid: gameProvider.gameGrid),
                        );
                      },
                    ),
                  ),
                ),

                // Fixed height spacing
                SizedBox(height: 20.h),

                // Game controller UI
                Container(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Up button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDirectionButton(
                              Icons.arrow_upward, Direction.up),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Left, Right buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDirectionButton(
                              Icons.arrow_back, Direction.left),
                          SizedBox(width: 80.w),
                          _buildDirectionButton(
                              Icons.arrow_forward, Direction.right),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Down button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDirectionButton(
                              Icons.arrow_downward, Direction.down),
                        ],
                      ),

                      // Speed control buttons
                      SizedBox(height: 16.h),
                      Consumer<SnakeGameProvider>(
                        builder: (context, gameProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Speed: ',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // Decrease speed button
                              InkWell(
                                onTap: () {
                                  gameProvider.decreaseSpeed();
                                  ToastUtils().showToast("Speed decreased");
                                },
                                child: Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  child:
                                      Icon(Icons.remove, color: Colors.black),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Speed indicator
                              Container(
                                width: 100.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      gameProvider.speedPercentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorPrimary,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Increase speed button
                              InkWell(
                                onTap: () {
                                  gameProvider.increaseSpeed();
                                  ToastUtils().showToast("Speed increased");
                                },
                                child: Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  child: Icon(Icons.add, color: Colors.black),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Game control buttons
                      SizedBox(height: 16.h),
                      Consumer<SnakeGameProvider>(
                        builder: (context, gameProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Reset button
                              ElevatedButton(
                                onPressed: () {
                                  gameProvider.initGame();
                                  gameProvider.startGame();
                                  ToastUtils().showToast("Game Reset");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                ),
                                child: Text('Reset',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              SizedBox(width: 16.w),
                              // Pause/Resume button
                              ElevatedButton(
                                onPressed: () {
                                  if (gameProvider.isGameRunning) {
                                    gameProvider.pauseGame();
                                    ToastUtils().showToast("Game Paused");
                                  } else {
                                    gameProvider.startGame();
                                    ToastUtils().showToast("Game Resumed");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gameProvider.isGameRunning
                                      ? Colors.red
                                      : Colors.green,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                ),
                                child: Text(
                                  gameProvider.isGameRunning
                                      ? 'Pause'
                                      : 'Resume',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Spacer at the bottom for balance
                SizedBox(height: 40.h),

                // Navigation buttons at the bottom
                Container(
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
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavButton(false, 'Badge', Icons.badge),
                        _buildNavButton(true, 'Game', Icons.gamepad),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build navigation button
  Widget _buildNavButton(bool isSelected, String label, IconData icon) {
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? colorPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorPrimary : Colors.grey,
            ),
            SizedBox(width: 8.w),
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

  // Build direction button for the game controller
  Widget _buildDirectionButton(IconData icon, Direction direction) {
    return Consumer<SnakeGameProvider>(
      builder: (context, gameProvider, child) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16.r),
          color: colorPrimary,
          child: InkWell(
            onTap: () {
              // Change snake direction
              gameProvider.changeDirection(direction);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              width: 70.w,
              height: 70.w,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}
