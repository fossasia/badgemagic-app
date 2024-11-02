import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:flutter/material.dart';

class DrawBadgeProvider extends ChangeNotifier {
  //List that contains the state of each cell of the badge for draw view
  List<List<bool>> _drawViewGrid =
      List.generate(11, (i) => List.generate(44, (j) => false));

  //getter for the drawViewGrid
  List<List<bool>> getDrawViewGrid() => _drawViewGrid;

  //setter for the drawViewGrid
  void setDrawViewGrid(int row, int col) {
    _drawViewGrid[row][col] = isDrawing;
    notifyListeners();
  }

  BadgeAnimation currentAnimation = LeftAnimation();

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    //copy the badgeData to the drawViewGrid and all the drawViewGrid after badgeData will remain unchanged
    for (int i = 0; i < _drawViewGrid.length; i++) {
      for (int j = 0; j < _drawViewGrid[0].length; j++) {
        if (j < badgeData[0].length) {
          _drawViewGrid[i][j] = badgeData[i][j];
        } else {
          _drawViewGrid[i][j] = false;
        }
      }
    }
    notifyListeners();
  }

  //function to reset the state of the cell
  void resetDrawViewGrid() {
    _drawViewGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    notifyListeners();
  }

  //boolean variable to check for isDrawing on Draw badge screen
  bool isDrawing = true;

  //function to toggle the isDrawing variable
  void toggleIsDrawing(bool drawing) {
    isDrawing = drawing;
    notifyListeners();
  }

  //function to get the isDrawing variable
  bool getIsDrawing() => isDrawing;
}
