import 'package:flutter/material.dart';
import 'package:piwallet/Components/LandingpageComponents/BottomNavigation.dart';

class LandingPage extends StatelessWidget {
  final String uid; // Accepting uid from sign-up page

  const LandingPage({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationPage(uid: uid);
  }
}
