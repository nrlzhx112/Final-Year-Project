import 'package:emindmatterssystem/screens/info/DisplayInfoListsPage.dart';
import 'package:emindmatterssystem/screens/info/DsiplayHelpcrisisPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter/material.dart';

import '../home/BottomNavBarPage.dart';

class TabBarInfoPage extends StatefulWidget {

  const TabBarInfoPage({Key? key}) : super(key: key);

  @override
  _TabBarInfoPageState createState() => _TabBarInfoPageState();
}

class _TabBarInfoPageState extends State<TabBarInfoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: Text(
          "Your Gateway to Learning",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Making the text bold
          ),
          textAlign: TextAlign.center, // Centering the text
        ),
        centerTitle: true,
        // Centering the title in the app bar
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white,),
        ),
        // Prevents the AppBar from showing the back button
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold, // Style for selected tab labels
            color: Colors.white,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal, // Style for unselected tab labels
            color: Colors.white.withOpacity(0.7),
          ),
          tabs: [
            Tab(text: 'Information'),
            Tab(text: 'Help Crisis'),
          ],
          indicatorColor: pShadeColor5,
          indicatorWeight: 4.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DisplayInfoListsPage(),
          DisplayHelpCrisisPage(), // Passing the userId here
        ],
      ),
    );
  }
}
