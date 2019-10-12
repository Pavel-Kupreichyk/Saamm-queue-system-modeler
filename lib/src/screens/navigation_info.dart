enum ScreenType { main, calc, data }

class NavigationInfo {
  static const mainRoute = '/';
  static const calcRoute = '/calc';
  static const dataRoute = '/data';

  final ScreenType screen;
  final Object args;

  String getRoute() {
    switch (screen) {
      case ScreenType.main:
        return mainRoute;
      case ScreenType.calc:
        return calcRoute;
      case ScreenType.data:
        return dataRoute;
    }
    return null;
  }

  NavigationInfo(this.screen, {this.args});
}
