import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../model data/GoalModel.dart';

class GoalAnalyticsPage extends StatefulWidget {
  @override
  _GoalAnalyticsPageState createState() => _GoalAnalyticsPageState();
}

class _GoalAnalyticsPageState extends State<GoalAnalyticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  void _initializeUserId() async {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        userId = user.uid; // Store the userId
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('goals').where('userId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No goals found'));
          }

          List<GoalModel> goals = snapshot.data!.docs.map((doc) =>
              GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          // Compute analytics data from goals
          int totalGoals = goals.length;
          int completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;
          double completionRate = totalGoals != 0 ? (completedGoals / totalGoals) * 100 : 0;

          // Wrap Column with SingleChildScrollView
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAnalyticsItem('Total Goals', totalGoals),
                  SizedBox(height: 10,),
                  _buildAnalyticsItem('Completed Goals', completedGoals),
                  SizedBox(height: 10,),
                  _buildAnalyticsItem('Completion Rate', '${completionRate.toStringAsFixed(2)}%'),
                  SizedBox(height: 10,),
                  _buildBarChart(completedGoals, totalGoals),
                  // Add more analytics items or charts as needed
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildAnalyticsItem(String label, dynamic value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: pShadeColor2, // A light shade for the background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: pShadeColor9, // Use a contrasting color for the text
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: pShadeColor5, // An accent color for the value container
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White or a light color for the value text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(int completedGoals, int totalGoals) {
    int uncompletedGoals = totalGoals - completedGoals; // Calculate uncompleted goals

    return Card(
      elevation: 5,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Goals Completion Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: pShadeColor7,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label = groupIndex == 0 ? 'Completed' : 'Uncompleted';
                        return BarTooltipItem(
                          '$label: ${rod.toY.toInt()} Goals',
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getTitles),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: 6.0),
                            child: Text(value == 0 ? 'Completed' : 'Uncompleted'),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    // Completed Goals Bar
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: completedGoals.toDouble(),
                          color: Colors.lightBlueAccent,
                          width: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                    // Uncompleted Goals Bar
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: uncompletedGoals.toDouble(),
                          color: Colors.orangeAccent,
                          width: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ],
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTitles(double value, TitleMeta meta) {
    return Padding(
      padding: EdgeInsets.only(top: 6.0),
      child: Text('${value.toInt()}'),
    );
  }

}

class GoalAnalytics {
  final int totalGoals;
  final int completedGoals;

  GoalAnalytics({
    required this.totalGoals,
    required this.completedGoals,
  });

  double get completionRate =>
      totalGoals != 0 ? (completedGoals / totalGoals) * 100 : 0;

  factory GoalAnalytics.fromMap(Map<String, dynamic> map) {
    return GoalAnalytics(
      totalGoals: map['totalGoals'] ?? 0,
      completedGoals: map['completedGoals'] ?? 0,
    );
  }
}
