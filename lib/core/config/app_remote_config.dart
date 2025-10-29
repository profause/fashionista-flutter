import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class AppRemoteConfig {
  static final AppRemoteConfig _instance = AppRemoteConfig._internal();
  factory AppRemoteConfig() => _instance;
  AppRemoteConfig._internal();

  static AppRemoteConfig get instance => _instance;

  late FirebaseRemoteConfig _remoteConfig;

  /// Initialize Remote Config and fetch latest values
  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Default fallback values (in case user is offline)
    // await _remoteConfig.setDefaults({
    //   'environments': jsonEncode({
    //     "dev": {
    //       "name": "dev",
    //       "recaptcha_site_key_android":
    //           "6LcvZLMrAAAAAC9BgMgVkpuuUZpxrBRW6rdvENEt",
    //       "recaptcha_site_key_ios": "6LerVrMrAAAAALXzsXfdT-v8p0iKKxIrK2FrByQU",
    //     },
    //     "prod": {
    //       "name": "prod",
    //       "recaptcha_site_key_android":
    //           "6LcvZLMrAAAAAC9BgMgVkpuuUZpxrBRW6rdvENEt",
    //       "recaptcha_site_key_ios": "6LerVrMrAAAAALXzsXfdT-v8p0iKKxIrK2FrByQU",
    //     },
    //   }),
    // });

    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config fetched');
    } catch (e) {
      debugPrint('⚠️ Remote Config fetch failed: $e');
    }
  }

  /// Fetch environments map (decoded from JSON)
  Map<String, dynamic> get environments {
    final raw = _remoteConfig.getString('environments');
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ Failed to decode environments: $e');
      return {};
    }
  }

  /// Select which environment to use (default = dev)
  // Map<String, dynamic> get currentEnv {
  //   const currentEnvName = String.fromEnvironment('ENV', defaultValue: 'dev');
  //   return environments[currentEnvName] ?? {};
  // }

  /// Determine current environment
  Map<String, dynamic> get currentEnv {
    // Priority:
    // 1. ENV from --dart-define
    // 2. Debug => dev
    // 3. Release => prod
    final envFromDefine = const String.fromEnvironment('ENV');
    final envName = envFromDefine.isNotEmpty
        ? envFromDefine
        : (kDebugMode ? 'dev' : 'prod');

    return environments[envName] ?? {};
  }

  /// Convenient getter for specific keys within the current environment
  dynamic get(String key) => currentEnv[key];

  /// For debugging: print all Firebase Remote Config parameters
  void debugPrintAll() {
    final params = _remoteConfig.getAll();
    for (final key in params.keys) {
      debugPrint('$key: ${params[key]!.asString()}');
    }
  }
}
