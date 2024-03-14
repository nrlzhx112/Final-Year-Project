import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/constant.dart';
import 'data/MoodEmojisModel.dart';
import 'data/MoodEntriesModel.dart';

class _BarChart extends StatefulWidget {
  final Map<String, int> dailyMoodCounts;
  final DateTime selectedDate;

  const _BarChart({required this.dailyMoodCounts, required this.selectedDate});

  @override
  __BarChartState createState() => __BarChartState();
}

class __BarChartState extends State<_BarChart> {
  Map<String, int> dailyMoodCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchDailyMoodCounts(widget.selectedDate);
  }

  String? getCurrentUserID() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      return user.uid; // This is the user ID
    } else {
      return null; // User is not authenticated
    }
  }

  Future<void> _fetchDailyMoodCounts(DateTime selectedDate) async { // Modify this line
    String? userID = getCurrentUserID();
    if (userID == null) {
      print("User is not authenticated.");
      return;
    }

    try {
      List<MoodEntryModel> entries = await MoodEntryModel.getAllMoodEntries(userID);

      // Filter entries to only include those from the selected date
      entries = entries.where((entry) => entry.moodDateTime.year == selectedDate.year && entry.moodDateTime.month == selectedDate.month && entry.moodDateTime.day == selectedDate.day).toList(); // Modify this line

      // Calculate daily mood counts
      Map<String, int> counts = MoodEntryModel.calculateDailyMoodCount(entries);

      setState(() {
        dailyMoodCounts = counts;
      });
    } catch (error) {
      print("Error fetching daily mood counts: $error");
    }
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
    String emoji;
    Color emojiColor;

    switch (value.toInt()) {
      case 0:
        emoji = MoodEmojisModel.excited;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[0].emojiName);
        break;
      case 1:
        emoji = MoodEmojisModel.happy;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[1].emojiName);
        break;
      case 2:
        emoji = MoodEmojisModel.tired;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[2].emojiName);
        break;
      case 3:
        emoji = MoodEmojisModel.neutral;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[3].emojiName);
        break;
      case 4:
        emoji = MoodEmojisModel.sad;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[4].emojiName);
        break;
      case 5:
        emoji = MoodEmojisModel.crying;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[5].emojiName);
        break;
      case 6:
        emoji = MoodEmojisModel.mad;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[6].emojiName);
        break;
      case 7:
        emoji = MoodEmojisModel.angry;
        emojiColor = MoodEmojisModel.getColorForMood(MoodEmojisModel.allMoods[6].emojiName);
        break;
      default:
        emoji = '';
        emojiColor = Colors.white; // Default color
        break;
    }

    final style = TextStyle(
      color: emojiColor, // Use the fetched emoji color
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(emoji, style: style),
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

  LinearGradient get _barsGradient => LinearGradient(
    colors: [
      pShadeColor6,
      pShadeColor3,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  List<BarChartGroupData> get barGroups {
    return dailyMoodCounts.entries.map((entry) {
      int index = MoodEmojisModel.allMoods.indexWhere((mood) => mood.emojiName == entry.key);
      return BarChartGroupData(
        x: index.toDouble().toInt(),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 16,
            gradient: _barsGradient,
          )
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }
}

class DailyMoodCountBarGraphPage extends StatefulWidget {
  final Map<String, int> moodCounts;
  final String timeframe;
  final DateTime selectedDate;

  const DailyMoodCountBarGraphPage({
    required this.moodCounts,
    required this.timeframe,
    required this.selectedDate,
  });

  @override
  State<StatefulWidget> createState() => DailyMoodCountBarGraphPageState();
}

class DailyMoodCountBarGraphPageState extends State<DailyMoodCountBarGraphPage> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: _BarChart(dailyMoodCounts: widget.moodCounts, selectedDate: widget.selectedDate),
    );
  }
}
