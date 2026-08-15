abstract class BadgeEffect {
  void processEffect(int animationIndex, List<List<bool>> canvas,
      int badgeHeight, int badgeWidth);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType && other.hashCode == hashCode;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
