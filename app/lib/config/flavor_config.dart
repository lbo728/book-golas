enum Flavor { dev, prod }

class FlavorConfig {
  static Flavor? _flavor;

  static void setFlavor(Flavor flavor) {
    _flavor = flavor;
  }

  static Flavor get flavor => _flavor ?? Flavor.dev;

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;
}
