import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'MoodEmojisModel.dart';

class TimeFrameUtils {
  static String getTimeFrameKey(DateTime date, String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return DateFormat('yyyy-MM-dd').format(date);
      case 'weekly':
        return '${DateFormat('yyyy').format(date)}-W${_getWeekNumber(date)}';
      case 'monthly':
        return DateFormat('yyyy-MM').format(date);
      case 'yearly':
        return DateFormat('yyyy').format(date);
      default:
        return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  static int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

class MoodEntryModel {
  final String moodEntryID;
  final String userID;
  DateTime moodDateTime;
  MoodEmojisModel moodType;
  int intensity;
  final String? notes;
  final DateTime createdAt;
  final String moodTypeName;

  MoodEntryModel({
    required this.moodEntryID,
    required this.userID,
    required this.moodDateTime,
    required String moodTypeName,
    this.notes,
  })  : createdAt = DateTime.now(),
        moodTypeName = _validateMoodTypeName(moodTypeName),
        moodType = _determineMoodType(moodTypeName),
        intensity = _assignIntensity(_determineMoodType(moodTypeName));

  int get moodIntensity => intensity;
  String get timeFrame => TimeFrameUtils.getTimeFrameKey(moodDateTime, 'daily');

  static String _validateMoodTypeName(String moodTypeName) {
    if (MoodEmojisModel.allMoods.any((mood) => mood.emojiName == moodTypeName)) {
      return moodTypeName;
    } else {
      // throw Exception('Invalid mood type name: $moodTypeName');
      return MoodEmojisModel.allMoods.first.emojiName; // Set to default mood if invalid
    }
  }

  static MoodEmojisModel _determineMoodType(String moodTypeName) {
    // Find the mood type from the list of all moods
    var mood = MoodEmojisModel.allMoods.firstWhere(
            (m) => m.emojiName == moodTypeName,
        orElse: () => MoodEmojisModel.allMoods.first // Default mood if not found
    );
    return mood;
  }

  Color getMoodColor() {
    return MoodEmojisModel.getColorForMood(moodType.emojiName);
  }

  // Method to assign intensity based on the mood type
  static int _assignIntensity(MoodEmojisModel moodType) {
    switch (moodType.emojiName) {
      case 'Very Happy':
        return 8;
      case 'Happy':
        return 7;
      case 'Neutral':
        return 6;
      case 'Somewhat Tired':
        return 5;
      case 'Sad':
        return 4;
      case 'Very Sad':
        return 3;
      case 'Angry':
        return 2;
      case 'Very Angry':
        return 1;
      default:
        return 6;  // Default intensity for unspecified moods
    }
  }

  factory MoodEntryModel.fromMap(Map<String, dynamic> map) {
    return MoodEntryModel(
      moodEntryID: map['moodEntryID'],
      userID: map['userID'],
      moodDateTime: (map['moodDateTime'] is Timestamp)
          ? (map['moodDateTime'] as Timestamp).toDate()
          : DateTime.parse(map['moodDateTime'] as String),
      moodTypeName: (map['moodTypeName'] is String)
          ? map['moodTypeName']
          : (map['moodTypeName'] as Map<String, dynamic>)['emojiName'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moodEntryID': moodEntryID,
      'userID': userID,
      'moodDateTime': moodDateTime.toIso8601String(),
      'moodTypeName': moodType.emojiName,
      'intensity': intensity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MoodEntryModel copyWith({
    String? moodEntryID,
    String? userID,
    DateTime? moodDateTime,
    String? moodTypeName,
    String? notes,
  }) {
    return MoodEntryModel(
      moodEntryID: moodEntryID ?? this.moodEntryID,
      userID: userID ?? this.userID,
      moodDateTime: moodDateTime ?? this.moodDateTime,
      moodTypeName: moodTypeName ?? this.moodTypeName,
      notes: notes ?? this.notes,
    );
  }

  static Future<List<MoodEntryModel>> getAllMoodEntries(String userID) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('moods')
          .where('userID', isEqualTo: userID)
          .orderBy('moodDateTime', descending: true)
          .get();

      return snapshot.docs.map((doc) => MoodEntryModel.fromMap(doc.data())).toList();
    } catch (error) {
      print("Error fetching mood entries: $error");
      throw error;
    }
  }

  static Stream<List<MoodEntryModel>> getAllMoodEntriesStream(String userID) {
    return FirebaseFirestore.instance
        .collection('moods')
        .where('userID', isEqualTo: userID)
        .orderBy('moodDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MoodEntryModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }


  Stream<Map<String, dynamic>> calculateMoodCount(Stream<List<MoodEntryModel>> moodEntriesStream, String timeframe) {
    return moodEntriesStream.map((moodEntries) {
      switch (timeframe.toLowerCase()) {
        case 'daily':
          return calculateDailyMoodCount(moodEntries);
        case 'weekly':
          return calculateWeeklyMoodCount(moodEntries);
        case 'monthly':
          return calculateMonthlyMoodCount(moodEntries);
        case 'yearly':
          return calculateYearlyMoodCount(moodEntries);
        default:
          throw Exception('Invalid time frame');
      }
    });
  }
// List of daily mood count
  static Map<String, int> calculateDailyMoodCount(List<MoodEntryModel> moodEntries) {
    // Get today's date
    DateTime today = DateTime.now();

    // Initialize a map to store mood counts
    Map<String, int> moodCountMap = {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Somewhat Tired': 0,
      'Sad': 0,
      'Very Sad': 0,
      'Angry': 0,
      'Very Angry': 0,
    };

    // Calculate mood counts for today across all users
    for (var entry in moodEntries) {
      if (entry.moodDateTime.year == today.year &&
          entry.moodDateTime.month == today.month &&
          entry.moodDateTime.day == today.day) {
        String moodName = entry.moodTypeName;
        moodCountMap[moodName] = moodCountMap[moodName]! + 1;
      }
    }

    return moodCountMap;
  }

  static Map<String, Map<String, int>> calculateWeeklyMoodCount(List<MoodEntryModel> moodEntries) {
    // Get the current date
    DateTime now = DateTime.now();
    // Start of the week (assuming week starts from Monday)
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // End of the week
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    Map<String, Map<String, int>> weeklyMoodCounts = _initializeWeeklyMoodCounts();

    for (var entry in moodEntries) {
      if (entry.moodDateTime.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          entry.moodDateTime.isBefore(endOfWeek.add(Duration(days: 1)))) {
        String dayName = DateFormat('EEEE').format(entry.moodDateTime); // Get day name like 'Monday'
        String moodKey = entry.moodTypeName; // Assuming this holds the mood name like 'Happy'
        weeklyMoodCounts[dayName]![moodKey] = (weeklyMoodCounts[dayName]![moodKey] ?? 0) + 1;
      }
    }

    return weeklyMoodCounts;
  }

  static Map<String, Map<String, int>> _initializeWeeklyMoodCounts() {
    return {
      'Monday': _initializeMoodCounts(),
      'Tuesday': _initializeMoodCounts(),
      'Wednesday': _initializeMoodCounts(),
      'Thursday': _initializeMoodCounts(),
      'Friday': _initializeMoodCounts(),
      'Saturday': _initializeMoodCounts(),
      'Sunday': _initializeMoodCounts(),
    };
  }

  static Map<String, int> _initializeMoodCounts() {
    return {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Somewhat Tired': 0,
      'Sad': 0,
      'Very Sad': 0,
      'Angry': 0,
      'Very Angry': 0,
    };
  }


  static Map<String, Map<String, int>> calculateMonthlyMoodCount(List<MoodEntryModel> moodEntries) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    // Initialize a map to store mood counts for each day of each month
    Map<String, Map<String, int>> monthlyMoodCounts = {};

    for (var month = 1; month <= 12; month++) {
      String monthName = _getMonthName(month); // Helper function to get the month name

      monthlyMoodCounts[monthName] = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Somewhat Tired': 0,
        'Sad': 0,
        'Very Sad': 0,
        'Angry': 0,
        'Very Angry': 0,
      };
    }

    // Iterate over each mood entry
    for (var entry in moodEntries) {
      if (entry.moodDateTime.month == currentMonth &&
          entry.moodDateTime.year == currentYear) {
        int month = entry.moodDateTime.month;
        String monthName = _getMonthName(
            month); // Helper function to get the month name

        // Increment the mood count for the corresponding month and mood intensity
        String moodKey = _getMoodKey1(
            entry.moodIntensity); // Helper function to get the mood key
        monthlyMoodCounts[monthName]![moodKey] =
            monthlyMoodCounts[monthName]![moodKey]! + 1;
      }
    }

    return monthlyMoodCounts;
  }

  static String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return 'Unknown';
    }
  }

  static String _getMoodKey1(int moodIntensity) {
    switch (moodIntensity) {
      case 8:
        return 'Very Happy';
      case 7:
        return 'Happy';
      case 6:
        return 'Neutral';
      case 5:
        return 'Somewhat Tired';
      case 4:
        return 'Sad';
      case 3:
        return 'Very Sad';
      case 2:
        return 'Angry';
      case 1:
        return 'Very Angry';
      default:
        return 'Unknown Mood';
    }
  }


//List of yearly mood count
  static Map<String, int> calculateYearlyMoodCount(List<MoodEntryModel> moodEntries) {
    // Get the current year
    int currentYear = DateTime.now().year;

    // Initialize a map to store mood counts
    Map<String, int> yearlyMoodCounts = {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Somewhat Tired': 0,
      'Sad': 0,
      'Very Sad': 0,
      'Angry': 0,
      'Very Angry': 0,
    };

    // Filter mood entries for the current year and aggregate counts
    for (var entry in moodEntries) {
      if (entry.moodDateTime.year == currentYear) {
        String moodName = entry.moodType.emojiName;
        yearlyMoodCounts[moodName] = yearlyMoodCounts[moodName]! + 1;
      }
    }

    return yearlyMoodCounts;
  }
}