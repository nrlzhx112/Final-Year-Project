import 'package:emindmatterssystem/components/BottomNavBarUser.dart';
import 'package:emindmatterssystem/screens/home/HomePage.dart';
import 'package:emindmatterssystem/screens/home/ReportPage.dart';
import 'package:emindmatterssystem/screens/user/ViewUserProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BottomNavBarPage extends StatefulWidget {

  BottomNavBarPage({Key? key}) : super(key: key);

  @override
  _BottomNavBarPageState createState() => _BottomNavBarPageState();
}

class _BottomNavBarPageState extends State<BottomNavBarPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    String? userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
    _pages = [
      HomePage(),
      ViewUserProfile(),
      userId != null ? ReportPage(userId: userId) : Container(),
    ];
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBarUser(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
