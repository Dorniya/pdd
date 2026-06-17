import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/main_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String main = '/main';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    main: (context) => const MainScreen(),
  };
}
