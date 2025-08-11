import 'package:flutter/material.dart';
import 'karma_dashboard_screen.dart';
import 'badge_gallery_screen.dart';

class KarmaHomeScreen extends StatelessWidget {
  final String uid;
  const KarmaHomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karma Home')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Karma Dashboard'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => KarmaDashboardScreen(uid: uid),
              ));
            },
          ),
          ListTile(
            title: const Text('Badge Gallery'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BadgeGalleryScreen(uid: uid),
              ));
            },
          ),
        ],
      ),
    );
  }
}

