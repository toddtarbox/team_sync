import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common mobile device screen sizes for testing
class ScreenSize {
  final String name;
  final Size size;
  final double devicePixelRatio;

  const ScreenSize(this.name, this.size, this.devicePixelRatio);

  // iPhone sizes
  static const iPhoneSE = ScreenSize('iPhone SE', Size(375, 667), 2.0);
  static const iPhone12Mini = ScreenSize('iPhone 12 Mini', Size(375, 812), 3.0);
  static const iPhone12 = ScreenSize('iPhone 12/13/14', Size(390, 844), 3.0);
  static const iPhone14Pro = ScreenSize('iPhone 14 Pro', Size(393, 852), 3.0);
  static const iPhone14ProMax =
      ScreenSize('iPhone 14 Pro Max', Size(430, 932), 3.0);
  static const iPhone15ProMax =
      ScreenSize('iPhone 15 Pro Max', Size(430, 932), 3.0);

  // Android sizes
  static const pixelSmall = ScreenSize('Pixel (Small)', Size(360, 640), 2.0);
  static const pixel5 = ScreenSize('Pixel 5', Size(393, 851), 2.75);
  static const pixel7 = ScreenSize('Pixel 7', Size(412, 915), 2.625);
  static const samsungGalaxyS21 =
      ScreenSize('Samsung Galaxy S21', Size(360, 800), 3.0);
  static const samsungGalaxyS23 =
      ScreenSize('Samsung Galaxy S23', Size(360, 780), 3.0);

  // Tablet sizes
  static const iPadMini = ScreenSize('iPad Mini', Size(744, 1133), 2.0);
  static const iPad = ScreenSize('iPad', Size(810, 1080), 2.0);
  static const iPadPro11 = ScreenSize('iPad Pro 11"', Size(834, 1194), 2.0);
  static const iPadPro129 = ScreenSize('iPad Pro 12.9"', Size(1024, 1366), 2.0);

  // Common sizes for quick testing
  static const small = ScreenSize('Small', Size(320, 568), 2.0); // iPhone 5
  static const medium = ScreenSize('Medium', Size(375, 667), 2.0); // iPhone SE
  static const large =
      ScreenSize('Large', Size(414, 896), 3.0); // iPhone 11 Pro Max
  static const extraLarge =
      ScreenSize('Extra Large', Size(428, 926), 3.0); // iPhone 12 Pro Max

  /// All common phone sizes
  static const List<ScreenSize> commonPhoneSizes = [
    iPhoneSE,
    iPhone12,
    iPhone14ProMax,
    pixelSmall,
    pixel7,
    samsungGalaxyS21,
  ];

  /// Quick test sizes (small, medium, large)
  static const List<ScreenSize> quickTestSizes = [
    small,
    medium,
    large,
  ];

  /// All sizes including tablets
  static const List<ScreenSize> allSizes = [
    small,
    iPhoneSE,
    iPhone12,
    iPhone14Pro,
    iPhone14ProMax,
    pixelSmall,
    pixel7,
    samsungGalaxyS21,
    iPadMini,
    iPad,
  ];
}

/// Extension to easily set screen size in tests
extension WidgetTesterScreenSize on WidgetTester {
  /// Set the screen size for testing
  Future<void> setScreenSize(ScreenSize screenSize) async {
    return binding.setSurfaceSize(screenSize.size);
  }

  /// Reset screen size to default
  Future<void> resetScreenSize() async {
    return binding.setSurfaceSize(null);
  }

  /// Set device pixel ratio
  void setDevicePixelRatio(double ratio) {
    view.devicePixelRatio = ratio;
  }

  /// Configure the test environment to match a specific screen size
  Future<void> configureScreenSize(ScreenSize screenSize) async {
    await setScreenSize(screenSize);
    setDevicePixelRatio(screenSize.devicePixelRatio);
  }
}
