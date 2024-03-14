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
  Map<String, Map<String, int>> monthlyMoodCounts = {};

  String? getCurrentUserID() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      return user.uid; // This is the user ID
    } else {
      return null; // User is not authenticated
    }
  }

  Future<void> _fetchMonthlyMoodCounts() async {
    String? userID = getCurrentUserID();
    if (userID == null) {
      print("User is not authenticated.");
      return;
    }

    try {
      List<MoodEntryModel> entries = await MoodEntryModel.getAllMoodEntries(userID);
      // Calculate monthly mood counts using the static method
      monthlyMoodCounts = MoodEntryModel.calculateMonthlyMoodCount(entries);

      setState(() {});
    } catch (error) {
      print("Error fetching monthly mood counts: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMonthlyMoodCounts(); // Call the method to fetch monthly mood counts
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

  BarTouchData get barTouchData =>
      BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (BarChartGroupData group,
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
        text = 'Jan';
        break;
      case 1:
        text = 'Feb';
        break;
      case 2:
        text = 'Mar';
        break;
      case 3:
        text = 'Apr';
        break;
      case 4:
        text = 'May';
        break;
      case 5:
        text = 'Jun';
        break;
      case 6:
        text = 'Jul';
        break;
      case 7:
        text = 'Aug';
        break;
      case 8:
        text = 'Sep';
        break;
      case 9:
        text = 'Oct';
        break;
      case 10:
        text = 'Nov';
        break;
      case 11:
        text = 'Dec';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 9,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData =>
      FlTitlesData(
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

  FlBorderData get borderData =>
      FlBorderData(
        show: false,
      );

  List<BarChartGroupData> get barGroups {
    List<BarChartGroupData> groups = [];
    List<Color> barColors = MoodEmojisModel.allMoods.map((mood) => MoodEmojisModel.getColorForMood(mood.emojiName)).toList();

    monthlyMoodCounts.forEach((month, moodCountMap) {
      List<BarChartRodData> rods = [];

      moodCountMap.entries.forEach((entry) {
        int moodIndex = MoodEmojisModel.allMoods.indexWhere((mood) => mood.emojiName == entry.key);
        if (moodIndex != -1) {
          rods.add(
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: barColors[moodIndex],  // Assign the color here
              width: 16, // Use the barWidth variable here
            ),
          );
        }
      });

      if (rods.isNotEmpty) {
        groups.add(
          BarChartGroupData(
            x: groups.length,
            barRods: rods,
          ),
        );
      }
    });
    return groups;
  }
}

class MonthlyMoodCountBarGraphPage extends StatefulWidget {
  final Map<String, int> moodCounts;
  final String timeframe;

  const MonthlyMoodCountBarGraphPage({
    required this.moodCounts,
    required this.timeframe,
  });

  @override
  State<StatefulWidget> createState() => MonthlyMoodCountBarGraphPageState();
}

class MonthlyMoodCountBarGraphPageState extends State<MonthlyMoodCountBarGraphPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(  // Use Padding to move the graph to the right
        padding: EdgeInsets.only(left: 20),  // Adjust this value as needed
        child: const AspectRatio(
          aspectRatio: 3.4,
          child: _BarChart(),
        ),
      ),
    );
  }
}