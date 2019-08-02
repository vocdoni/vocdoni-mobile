String patternToString(List<int> pattern, {int gridSize = 5}) {
  String stringPattern = "";
  for (int i = 0; i < pattern.length - 1; i++) {
    stringPattern += (pattern[i].toRadixString(gridSize * gridSize));
  }
  return stringPattern;
}
