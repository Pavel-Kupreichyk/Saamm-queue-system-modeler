enum ScreenType { main, calc, data, sim }

class NavigationInfo {
  static const mainRoute = '/';
  static const calcRoute = '/calc';
  static const dataRoute = '/data';
  static const simRoute = '/sim';

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
      case ScreenType.sim:
        return simRoute;
    }
    return null;
  }

  NavigationInfo(this.screen, {this.args});
}
