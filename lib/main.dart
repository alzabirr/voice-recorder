import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/record_provider.dart';
import 'screens/record_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: CupertinoColors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecordProvider()),
      ],
      child: const CupertinoApp(
        title: 'Voice Recorder',
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemRed,
          scaffoldBackgroundColor: CupertinoColors.black,
          barBackgroundColor: CupertinoColors.black,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.white,
            ),
          ),
        ),
        home: RecordScreen(),
      ),
    );
  }
}
