import 'package:book_golas/config/flavor_config.dart';
import 'package:book_golas/main.dart' as app;

void main() {
  FlavorConfig.setFlavor(Flavor.dev);
  app.main();
}
