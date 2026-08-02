import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation helper that adapts navigation behavior based on platform
/// - Web: Uses context.go() for URL-based navigation (replaces current route)
/// - Mobile: Uses context.push() for stack-based navigation (maintains back button)
class NavigationHelper {
  /// Navigate to a route using the appropriate method for the platform
  ///
  /// On web, this uses go() which replaces the URL and current route.
  /// On mobile, this uses push() which adds to the navigation stack.
  static void navigateTo(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    if (kIsWeb) {
      context.go(location, extra: extra);
    } else {
      context.push(location, extra: extra);
    }
  }

  /// Always push regardless of platform (useful for modals/dialogs)
  static void pushRoute(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    context.push(location, extra: extra);
  }

  /// Always replace regardless of platform (useful for redirects)
  static void replaceRoute(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    context.go(location, extra: extra);
  }
}
