import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.userBox),
      Hive.openBox(AppConstants.cacheBox),
    ]);
  }

  static Box get settings => Hive.box(AppConstants.settingsBox);
  static Box get user => Hive.box(AppConstants.userBox);
  static Box get cache => Hive.box(AppConstants.cacheBox);

  static Future<void> put(String boxName, String key, dynamic value) async {
    await Hive.box(boxName).put(key, value);
  }

  static T? get<T>(String boxName, String key) {
    return Hive.box(boxName).get(key) as T?;
  }

  static Future<void> delete(String boxName, String key) async {
    await Hive.box(boxName).delete(key);
  }

  static Future<void> clearBox(String boxName) async {
    await Hive.box(boxName).clear();
  }
}
