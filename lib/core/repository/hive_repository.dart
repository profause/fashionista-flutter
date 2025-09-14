
abstract class HiveRepository<T> {
  Future<List<T>> getItems(String key);
  Future<T> getItem(String key,String identifier);
  Future<void> insertItems(String key,{required List<T> items});
  Future<bool> isCacheEmpty();
  Future<void> clearCache();
}