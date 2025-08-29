
abstract class HiveRepository<T> {
  Future<List<T>> getItems();
  Future<void> insertItems({required List<T> items});
  Future<bool> isCacheEmpty();
  Future<void> clearCache();
}