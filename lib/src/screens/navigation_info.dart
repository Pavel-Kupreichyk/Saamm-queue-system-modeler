enum ScreenType { main, calc }

class NavigationInfo {
  static const mainRoute = '/';
  static const calcRoute = '/calc';

  final ScreenType screen;
  final Object args;

  String getRoute() {
    switch (screen) {
      case ScreenType.main:
        return mainRoute;
      case ScreenType.calc:
        return calcRoute;
    }
    return null;
  }

  NavigationInfo(this.screen, {this.args});
}
