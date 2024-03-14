import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/mood/DailyMoodCountBarGraphPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../MonthlyMoodCountBarGraphPage.dart';
import '../WeeklyMoodCountBarGraphPage.dart';
import '../YearlyMoodCountBarGraphPage.dart';
import '../data/MoodEntriesModel.dart';

class BarChartAnalyticPage extends StatefulWidget {

  @override
  State<BarChartAnalyticPage> createState() => _BarChartAnalyticPage();
}

class _BarChartAnalyticPage extends State<BarChartAnalyticPage> with SingleTickerProviderStateMixin {
  Stream<List<MoodEntryModel>>? moodEntriesStream; // Stream to hold mood entries
  String _selectedTimeframe = 'daily'; // Default timeframe
  Map<String, int> moodCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      moodEntriesStream = _getMoodEntriesStream(userId);
      _calculateMoodCounts(_selectedTimeframe);
    }
  }

  Stream<List<MoodEntryModel>> _getMoodEntriesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('moods')
        .where('userID', isEqualTo: userId)
        .orderBy('moodDateTime', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            MoodEntryModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Map<String, int> _calculateMoodCountsForTimeframe(String timeframe,
      List<MoodEntryModel> moodEntries) {
    Map<String, int> moodCounts = {};

    // Filter mood entries based on the selected timeframe
    DateTime now = DateTime.now();
    DateTime startDateTime;

    switch (timeframe) {
      case 'daily':
        startDateTime = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDateTime = now.subtract(
            Duration(days: now.weekday - 1)); // Start of the week (Sunday)
        break;
      case 'monthly':
        startDateTime = DateTime(now.year, now.month, 1);
        break;
      case 'yearly':
        startDateTime = DateTime(now.year, 1, 1);
        break;
      default:
        startDateTime = now;
        break;
    }

    // Count mood entries for the selected timeframe
    for (var moodEntry in moodEntries) {
      if (moodEntry.moodDateTime.isAfter(startDateTime)) {
        String moodTypeName = moodEntry.moodType.emojiName;
        moodCounts[moodTypeName] = (moodCounts[moodTypeName] ?? 0) + 1;
      }
    }

    return moodCounts;
  }

  void _calculateMoodCounts(String timeframe) {
    if (moodEntriesStream != null) {
      moodEntriesStream!.listen((moodEntries) {
        setState(() {
          moodCounts = _calculateMoodCountsForTimeframe(timeframe, moodEntries);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _selectedTimeframe,
              items: ['daily', 'weekly', 'monthly', 'yearly'].map((
                  String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTimeframe = newValue!;
                });
                _calculateMoodCounts(_selectedTimeframe);
              },
            ),
            // Display the mood counts here using a bar chart or any other widget
            if (moodCounts.isNotEmpty)
              Expanded(
                child: _selectedTimeframe == 'daily'
                    ? DailyMoodCountBarGraphPage(
                  moodCounts: moodCounts,
                  timeframe: _selectedTimeframe,
                  selectedDate: DateTime.now(),
                )
                    : _selectedTimeframe == 'weekly'
                    ? WeeklyMoodCountBarGraphPage(
                  moodCounts: moodCounts,
                  timeframe: _selectedTimeframe,
                )
                    : _selectedTimeframe == 'monthly'
                    ? MonthlyMoodCountBarGraphPage(
                  moodCounts: moodCounts,
                  timeframe: _selectedTimeframe,
                )
                    : YearlyMoodCountBarGraphPage(
                  moodCounts: moodCounts,
                  timeframe: _selectedTimeframe,
                ),
              ),
          ],
        ),
      ),
    );
  }
}