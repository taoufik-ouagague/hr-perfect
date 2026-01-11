import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'controllers/controller.dart';
import 'screens/employee/employee_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
   
    Get.put(HRController(), permanent: true);

    return GetMaterialApp(
      title: 'HR Perfect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      initialRoute: '/splash',

      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
          name: '/home',
          page: () {
            final controller = Get.find<HRController>();
            return EmployeeHome(userId: controller.userId.value);
          },
        ),
      ],
    );
  }
}
