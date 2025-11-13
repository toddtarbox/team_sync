// Web implementation of TwitterFeed using HtmlElementView
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:js/js_util.dart' as js_util;

class TwitterFeed extends StatefulWidget {
  final String username;
  final double height;
  final Map<String, String>? options;
  final Widget Function(String error)? onError;

  const TwitterFeed(
      {Key? key,
      required this.username,
      this.height = 400,
      this.options,
      this.onError})
      : super(key: key);

  @override
  State<TwitterFeed> createState() => _TwitterFeedState();
}

class _TwitterFeedState extends State<TwitterFeed> {
  static final Set<String> _registeredViewTypes = {};
  late final String _viewType;
  bool _registrationFailed = false;
  bool _hasLoggedError = false;

  @override
  void initState() {
    super.initState();

    _viewType = 'twitter-timeline-${widget.username.replaceAll('@', '')}';

    // Register the view factory only once per viewType
    if (!_registeredViewTypes.contains(_viewType)) {
      if (kIsWeb) {
        if (kDebugMode) {
          print(
              'Twitter feed: Attempting to register view for ${widget.username}');
        }

        try {
          if (kDebugMode) {
            print(
                'Twitter feed: Registering platform view factory for $_viewType');
          }

          // Use the modern ui_web API to register the platform view
          ui_web.platformViewRegistry.registerViewFactory(
            _viewType,
            (int viewId) {
              if (kDebugMode) {
                print(
                    'Twitter feed: Factory callback invoked for viewId: $viewId');
              }

              // Create a div element that will host the timeline
              final document =
                  js_util.getProperty(js_util.globalThis, 'document');
              final Object div =
                  js_util.callMethod(document, 'createElement', ['div']);

              final theme = widget.options?['theme'] ?? 'light';
              final height = widget.height.toInt();

              // Set initial loading message
              js_util.setProperty(
                  div,
                  'innerHTML',
                  '<div style="display: flex; align-items: center; justify-content: center; height: ${height}px; padding: 20px; text-align: center; color: #657786; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif;">'
                      '<div>'
                      '<p style="font-size: 32px; margin: 20px 0;">🐦</p>'
                      '<p style="font-size: 16px; margin: 10px 0;">Loading timeline...</p>'
                      '</div>'
                      '</div>');

              // Inject Twitter script if needed
              final existing = js_util
                  .callMethod(document, 'getElementById', ['twitter-wjs']);

              void createTimeline() {
                try {
                  final twttr =
                      js_util.getProperty(js_util.globalThis, 'twttr');
                  if (kDebugMode) {
                    print(
                        'Twitter feed: twttr object is ${twttr != null ? "available" : "null"}');
                  }
                  if (twttr != null) {
                    final widgets = js_util.getProperty(twttr, 'widgets');
                    if (kDebugMode) {
                      print(
                          'Twitter feed: twttr.widgets is ${widgets != null ? "available" : "null"}');
                    }
                    if (widgets != null) {
                      if (kDebugMode) {
                        print(
                            'Twitter feed: Calling twttr.widgets.createTimeline()');
                      }

                      // Create options object for the timeline
                      final options = js_util.newObject();
                      js_util.setProperty(options, 'height', height);
                      js_util.setProperty(options, 'theme', theme);

                      // Create timeline using the Twitter API
                      // Format: {sourceType: 'profile', screenName: 'username'}
                      final dataSource = js_util.newObject();
                      js_util.setProperty(dataSource, 'sourceType', 'profile');
                      js_util.setProperty(
                          dataSource, 'screenName', widget.username);

                      if (kDebugMode) {
                        print(
                            'Twitter feed: Creating timeline for username: ${widget.username}');
                        print('Twitter feed: height: $height, theme: $theme');
                      }

                      final result = js_util.callMethod(
                        widgets,
                        'createTimeline',
                        [dataSource, div, options],
                      );

                      if (kDebugMode) {
                        print(
                            'Twitter feed: createTimeline() returned: $result');
                      }

                      // Convert the Promise to a Dart Future and handle it
                      if (result != null) {
                        js_util.promiseToFuture(result).then((value) {
                          if (kDebugMode) {
                            print(
                                'Twitter feed: ✅ Timeline created successfully!');
                            print('Twitter feed: Result value: $value');

                            // Check if the timeline element was actually created
                            final children =
                                js_util.getProperty(div, 'children');
                            if (children != null) {
                              final length =
                                  js_util.getProperty(children, 'length');
                              print('Twitter feed: Div has $length children');
                            }
                          }
                        }).catchError((error) {
                          if (kDebugMode) {
                            print('Twitter feed: ❌ Timeline creation failed!');
                            print('Twitter feed: Error: $error');
                            print(
                                'Twitter feed: Error type: ${error.runtimeType}');
                          }

                          // Display rate limit error message in the div
                          final errorMsg = error.toString().toLowerCase();
                          final errorHtml = errorMsg.contains('rate') ||
                                  errorMsg.contains('limit')
                              ? '<div style="display: flex; align-items: center; justify-content: center; height: ${height}px; padding: 20px; text-align: center; color: #657786; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif; background-color: #f7f9fa; border-radius: 8px;">'
                                  '<div>'
                                  '<p style="font-size: 48px; margin: 20px 0;">⏱️</p>'
                                  '<p style="font-size: 16px; font-weight: bold; margin: 10px 0; color: #14171A;">Rate Limit Exceeded</p>'
                                  '<p style="font-size: 14px; margin: 10px 0; line-height: 1.5;">Twitter\'s API rate limit has been reached.</p>'
                                  '<p style="font-size: 14px; margin: 10px 0; line-height: 1.5;">Please wait a few minutes and refresh the page.</p>'
                                  '<p style="font-size: 12px; margin: 20px 0; color: #AAB8C2;">This is a temporary Twitter API limitation.</p>'
                                  '</div>'
                                  '</div>'
                              : '<div style="display: flex; align-items: center; justify-content: center; height: ${height}px; padding: 20px; text-align: center; color: #657786; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif; background-color: #f7f9fa; border-radius: 8px;">'
                                  '<div>'
                                  '<p style="font-size: 48px; margin: 20px 0;">❌</p>'
                                  '<p style="font-size: 16px; font-weight: bold; margin: 10px 0; color: #14171A;">Unable to Load Timeline</p>'
                                  '<p style="font-size: 14px; margin: 10px 0; line-height: 1.5;">Failed to load tweets from @${widget.username}</p>'
                                  '<p style="font-size: 12px; margin: 20px 0; color: #AAB8C2; word-break: break-word;">Error: $error</p>'
                                  '</div>'
                                  '</div>';
                          js_util.setProperty(div, 'innerHTML', errorHtml);
                        });
                      }
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Twitter feed: Error creating timeline: $e');
                  }
                }
              }

              if (existing == null) {
                if (kDebugMode) {
                  print('Twitter feed: Injecting Twitter widgets.js script');
                }
                final script =
                    js_util.callMethod(document, 'createElement', ['script']);
                js_util.setProperty(script, 'id', 'twitter-wjs');
                js_util.setProperty(
                    script, 'src', 'https://platform.twitter.com/widgets.js');
                js_util.setProperty(script, 'async', true);

                // Add onload callback to create timeline when script loads
                js_util.setProperty(script, 'onload',
                    js_util.allowInterop((event) {
                  if (kDebugMode) {
                    print('Twitter feed: widgets.js loaded, creating timeline');
                  }
                  // Use setTimeout to ensure DOM is ready
                  js_util.callMethod(js_util.globalThis, 'setTimeout', [
                    js_util.allowInterop(() {
                      createTimeline();
                    }),
                    100 // Small delay
                  ]);
                }));

                final head = js_util.getProperty(document, 'head');
                js_util.callMethod(head, 'appendChild', [script]);
              } else {
                if (kDebugMode) {
                  print(
                      'Twitter feed: Twitter widgets.js script already loaded');
                }
                // Script already loaded, create timeline immediately with small delay
                js_util.callMethod(js_util.globalThis, 'setTimeout', [
                  js_util.allowInterop(() {
                    createTimeline();
                  }),
                  100 // Small delay
                ]);
              }

              return div;
            },
          );

          _registeredViewTypes.add(_viewType);
          if (kDebugMode) {
            print('Twitter feed: Successfully registered $_viewType');
          }
        } catch (e) {
          // registration failed
          if (kDebugMode) {
            print('Twitter feed registration failed: $e');
            print('Twitter feed error stack: ${StackTrace.current}');
          }
          _registrationFailed = true;
        }
      }
    } else {
      if (kDebugMode) {
        print('Twitter feed: View type $_viewType already registered');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    // Show error widget if registration failed
    if (_registrationFailed && widget.onError != null) {
      if (kDebugMode && !_hasLoggedError) {
        print(
            'Twitter feed: Showing error widget - registration failed for ${widget.username}');
        _hasLoggedError = true;
      }
      return widget.onError!('Failed to register Twitter feed view');
    }

    // If no view was registered, show a fallback
    if (!_registeredViewTypes.contains(_viewType)) {
      if (kDebugMode && !_hasLoggedError) {
        print('Twitter feed: View type not registered for ${widget.username}');
        _hasLoggedError = true;
      }
      if (widget.onError != null) {
        return widget.onError!('Twitter feed not available');
      }
      return const Center(
        child: Text('Twitter feed could not be loaded'),
      );
    }

    if (kDebugMode && !_hasLoggedError) {
      print('Twitter feed: Rendering HtmlElementView for ${widget.username}');
      _hasLoggedError = true;
    }

    return SizedBox(
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
