/// Storage backend mode for the app's data layer.
///
/// [offline] (the default) reads/writes exclusively via the local SQLite
/// database. [online] reads/writes exclusively via the admin's own MongoDB
/// cluster (credentials supplied at runtime in Settings, never hardcoded).
enum DataMode {
  offline,
  online;

  static DataMode fromStorageValue(String? value) {
    return value == 'online' ? DataMode.online : DataMode.offline;
  }

  String toStorageValue() => name;
}
