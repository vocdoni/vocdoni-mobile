String normalizeAnswers(String concatenatedAnswers) {
  String normalized = concatenatedAnswers.replaceAll(RegExp(r"\s+"), "");
  normalized = normalized.toLowerCase();
  return normalized;
}
