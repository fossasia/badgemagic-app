class ClipartImageProcessor {
  static const int _badgeRows = 11;

  static List<List<int>> trimEmptyPadding(List<List<int>> image) {
    if (image.isEmpty || image[0].isEmpty) return const [];

    final int rows = image.length;
    final int cols = image[0].length;
    int left = cols, right = -1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (image[r][c] != 0) {
          if (c < left) left = c;
          if (c > right) right = c;
        }
      }
    }

    if (right < 0) return const [];

    return List.generate(
      rows,
      (i) => image[i].sublist(left, right + 1),
    );
  }

  static List<List<int>> normalizeClipartHeight(List<List<int>> image) {
    if (image.isEmpty) return image;
    final int cols = image[0].length;
    if (image.length == _badgeRows) return image;

    if (image.length < _badgeRows) {
      final int missing = _badgeRows - image.length;
      final int top = missing ~/ 2;
      final int bottom = missing - top;
      return [
        for (int i = 0; i < top; i++) List<int>.filled(cols, 0),
        ...image,
        for (int i = 0; i < bottom; i++) List<int>.filled(cols, 0),
      ];
    }

    return image.sublist(0, _badgeRows);
  }

  static List<List<int>> addClipartSideMargins(List<List<int>> image) {
    if (image.isEmpty) return image;
    return [
      for (final row in image) <int>[0, ...row, 0],
    ];
  }
}
