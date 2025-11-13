// Non-web fallback for TwitterFeed
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TwitterFeed extends StatelessWidget {
  final String username;
  final double height;
  final Widget Function(String error)? onError;

  const TwitterFeed(
      {Key? key, required this.username, this.height = 200, this.onError})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final url = Uri.https('twitter.com', '/$username');
    return SizedBox(
      height: height,
      child: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (!await launchUrl(url)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Twitter')),
              );
            }
          },
          child: Text('Open @$username on Twitter'),
        ),
      ),
    );
  }
}
