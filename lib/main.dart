import 'package:flutter/material.dart';
import 'package:flutter_saimmod_3/src/screens/calc_screen.dart';
import 'package:flutter_saimmod_3/src/screens/data_screen.dart';
import 'package:flutter_saimmod_3/src/screens/main_screen.dart';
import 'package:flutter_saimmod_3/src/screens/navigation_info.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreenBuilder(),
      onGenerateRoute: _navigate,
    );
  }

  MaterialPageRoute _navigate(RouteSettings settings) {
    Widget newScreen;
    switch (settings.name) {
      case NavigationInfo.calcRoute:
        newScreen = CalcScreenBuilder(settings.arguments);
        break;
      case NavigationInfo.dataRoute:
        newScreen = DataScreenBuilder(settings.arguments);
        break;
      default:
        throw Exception('Invalid route: ${settings.name}');
    }
    return MaterialPageRoute(builder: (_) => newScreen);
  }
}
