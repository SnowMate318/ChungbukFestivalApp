import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'bindings/initial_biding.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(380, 680),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'greenfestival',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'HakgyoansimAllimjang'),
          initialBinding: InitialBinding(),
          getPages: AppPages.pages,
          initialRoute: AppPages.INITIAL,
        );
      },
    );
  }
}
