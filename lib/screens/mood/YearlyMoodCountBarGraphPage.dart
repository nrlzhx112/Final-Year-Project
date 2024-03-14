import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/constant.dart';
import 'data/MoodEmojisModel.dart';
import 'data/MoodEntriesModel.dart';


class _BarChart extends StatefulWidget {
  const _BarChart();

  @override
  __BarChartState createState() => __BarChartState();
}

class __BarChartState extends State<_BarChart> {
  Map<String, Map<String, int>> yearlyMoodCounts = {};

  String? getCurrentUserID() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      return user.uid; // This is the user ID
    } else {
      return null; // User is not authenticated
    }
  }

  Future<void> _fetchYearlyMoodCounts() async {
    String? userID = getCurrentUserID();
    if (userID == null) {
      print("User is not authenticated.");
      return;
    }

    try {
      List<MoodEntryModel> entries = await MoodEntryModel.getAllMoodEntries(userID);
      // Calculate yearly mood counts for each year from 2023 to 2030
      for (int year = 2024; year <= 2030; year++) {
        List<MoodEntryModel> yearlyEntries = entries.where((entry) => entry.moodDateTime.year == year).toList();
        Map<String, int> counts = MoodEntryModel.calculateYearlyMoodCount(yearlyEntries);
        yearlyMoodCounts['$year'] = counts;
      }

      setState(() {});
    } catch (error) {
      print("Error fetching yearly mood counts: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchYearlyMoodCounts(); // Call the method to fetch yearly mood counts
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData,
        borderData: borderData,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
    enabled: false,
    touchTooltipData: BarTouchTooltipData(
      tooltipBgColor: Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: 8,
      getTooltipItem: (
          BarChartGroupData group,
          int groupIndex,
          BarChartRodData rod,
          int rodIndex,
          ) {
        return BarTooltipItem(
          rod.toY.round().toString(),
          TextStyle(
            color: pShadeColor3,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: pShadeColor5,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '2024';
        break;
      case 1:
        text = '2025';
        break;
      case 2:
        text = '2026';
        break;
      case 3:
        text = '2027';
        break;
      case 4:
        text = '2028';
        break;
      case 5:
        text = '2029';
        break;
      case 6:
        text = '2030';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: getTitles,
      ),
    ),
    leftTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  FlBorderData get borderData => FlBorderData(
    show: false,
  );

  List<BarChartGroupData> get barGroups {
    List<BarChartGroupData> groups = [];
    List<Color> barColors = MoodEmojisModel.allMoods.map((mood) => MoodEmojisModel.getColorForMood(mood.emojiName)).toList();

    yearlyMoodCounts.forEach((year, moodCountMap) {
      List<BarChartRodData> rods = [];

      moodCountMap.entries.forEach((entry) {
        int moodIndex = MoodEmojisModel.allMoods.indexWhere((mood) => mood.emojiName == entry.key);
        if (moodIndex != -1) {
          rods.add(
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: barColors[moodIndex],
              width: 16,
            ),
          );
        }
      });

      groups.add(
        BarChartGroupData(
          x: groups.length,
          barRods: rods,
        ),
      );
    });

    return groups;
  }
}

class YearlyMoodCountBarGraphPage extends StatefulWidget {
  final Map<String, int> moodCounts;
  final String timeframe;

  const YearlyMoodCountBarGraphPage({
    required this.moodCounts,
    required this.timeframe,
  });

  @override
  State<StatefulWidget> createState() => YearlyMoodCountBarGraphPageState();
}

class YearlyMoodCountBarGraphPageState extends State<YearlyMoodCountBarGraphPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(  // Use Padding to move the graph to the right
        padding: EdgeInsets.only(left: 5),  // Adjust this value as needed
        child: const AspectRatio(
          aspectRatio: 2.4,
          child: _BarChart(),
        ),
      ),
    );
  }
}