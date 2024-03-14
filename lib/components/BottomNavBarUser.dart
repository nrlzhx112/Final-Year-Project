import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavBarUser extends StatefulWidget {
  final void Function(int)? onTabChange;

  BottomNavBarUser({Key? key, required this.onTabChange}) : super(key: key);

  @override
  _BottomNavBarUserState createState() => _BottomNavBarUserState();
}

class _BottomNavBarUserState extends State<BottomNavBarUser> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
        child: GNav(
          onTabChange: (value) => widget.onTabChange!(value),
          backgroundColor: Colors.transparent,
          color: pShadeColor9,
          mainAxisAlignment: MainAxisAlignment.center,
          activeColor: Colors.white,
          tabBackgroundColor: pShadeColor4,
          tabBorderRadius: 200,
          tabActiveBorder: Border.all(color: pShadeColor2),
          tabs: const [
            GButton(
              icon: Icons.home_filled,
              text: 'Home',
            ),
            GButton(
              icon: Icons.person,
              text: 'Profile',
            ),
            GButton(
              icon: Icons.analytics,
              text: 'Analytic',
            ),
          ],
        ),
    );
  }
}
