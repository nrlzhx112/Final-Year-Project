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
  Map<String, Map<String, int>> weeklyMoodCounts = {};

  String? getCurrentUserID() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      return user.uid; // This is the user ID
    } else {
      return null; // User is not authenticated
    }
  }

  // Adjusting the _fetchDailyMoodCounts method to fetch weekly mood counts
  Future<void> _fetchWeeklyMoodCounts() async {
    String? userID = getCurrentUserID();
    if (userID == null) {
      print("User is not authenticated.");
      return;
    }

    try {
      List<MoodEntryModel> entries = await MoodEntryModel.getAllMoodEntries(userID);
      // Calculate weekly mood counts
      Map<String, Map<String, int>> weeklyCounts = MoodEntryModel.calculateWeeklyMoodCount(entries);

      setState(() {
        weeklyMoodCounts = weeklyCounts; // Rename this variable to represent weekly counts
      });
    } catch (error) {
      print("Error fetching weekly mood counts: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeeklyMoodCounts(); // Call the method to fetch weekly mood counts
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
        text = 'Mn';
        break;
      case 1:
        text = 'Tu';
        break;
      case 2:
        text = 'Wd';
        break;
      case 3:
        text = 'Tu';
        break;
      case 4:
        text = 'Fr';
        break;
      case 5:
        text = 'St';
        break;
      case 6:
        text = 'Sn';
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

    // Define bar colors based on mood emojis
    List<Color> barColors = MoodEmojisModel.allMoods.map((mood) => MoodEmojisModel.getColorForMood(mood.emojiName)).toList();

    weeklyMoodCounts.forEach((day, moodCounts) {
      List<BarChartRodData> rods = [];

      int index = 0;
      moodCounts.forEach((moodName, count) {
        rods.add(
          BarChartRodData(
            toY: count.toDouble(),
            width: 16.0,
            color: barColors[index],  // Set bar color
          ),
        );
        index = (index + 1) % barColors.length;  // Rotate through colors
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

class WeeklyMoodCountBarGraphPage extends StatefulWidget {
  final Map<String, int> moodCounts;
  final String timeframe;

  const WeeklyMoodCountBarGraphPage({
    required this.moodCounts,
    required this.timeframe,
  });

  @override
  State<StatefulWidget> createState() => WeeklyMoodCountBarGraphPageState();
}

class WeeklyMoodCountBarGraphPageState extends State<WeeklyMoodCountBarGraphPage> {
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