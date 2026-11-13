import 'package:flutter/material.dart';
import 'theme.dart';
import 'routes.dart';

class PropertyValuerProApp extends StatelessWidget {
  const PropertyValuerProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Valuer Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.dashboard,
      routes: AppRoutes.routes,
    );
  }
}

