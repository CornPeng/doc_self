import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // 默认英文
  static const String _languageKey = 'selected_language';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      // 如果用户之前选择过语言，使用用户选择的语言
      _locale = Locale(languageCode);
    } else {
      // 如果是第一次使用，根据系统语言设置
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode == 'zh') {
        _locale = const Locale('zh');
      } else {
        _locale = const Locale('en');
      }
      // 保存默认语言
      await prefs.setString(_languageKey, _locale.languageCode);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  void clearLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }
}
