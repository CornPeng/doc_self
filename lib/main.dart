import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:soul_note/theme/app_theme.dart';
import 'package:soul_note/screens/main_navigation.dart';
import 'package:soul_note/l10n/app_localizations.dart';
import 'package:soul_note/providers/language_provider.dart';
import 'package:soul_note/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // 初始化同步服务
  await SyncService().initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const SoulNoteApp(),
    ),
  );
}

class SoulNoteApp extends StatelessWidget {
  const SoulNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'SoulNote',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('zh', ''),
          ],
          home: const MainNavigation(),
        );
      },
    );
  }
}
