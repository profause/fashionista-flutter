
abstract class HiveRepository<T> {
  Future<List<T>> getItems(String key);
  Future<void> insertItems(String key,{required List<T> items});
  Future<bool> isCacheEmpty();
  Future<void> clearCache();
}