import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/GoalAnalyticsPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter/material.dart';
import '../mood/pages/BarChartAnalyticPage.dart';

class ReportPage extends StatefulWidget {
  final String userId;

  const ReportPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
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
            "Reports",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold, // Making the text bold
            ),
            textAlign: TextAlign.center, // Centering the text
          ),
          centerTitle: true,
          // Centering the title in the app bar
          elevation: 0,
          automaticallyImplyLeading: false,
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
              Tab(text: 'Goal Statistics'),
              Tab(text: 'Mood Analytics'),
            ],
            indicatorColor: pShadeColor5,
            indicatorWeight: 4.0,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            GoalAnalyticsPage(),
            BarChartAnalyticPage(), // Passing the userId here
          ],
        ),
      );
  }
}
