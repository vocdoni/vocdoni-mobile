makeElementTag(String entityId, String itemId, int index) {
  return entityId + "/" + itemId + "/" + (index ?? '').toString();
}
