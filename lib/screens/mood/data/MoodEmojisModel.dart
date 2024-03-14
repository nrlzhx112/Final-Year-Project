import 'package:flutter/material.dart';

class MoodEmojisModel {
  final String emojiName;
  final String emoji;
  Color get emojiColor => _emojiColor;
  late Color _emojiColor;


  MoodEmojisModel({
    required this.emojiName,
    required this.emoji,
    required Color emojiColor,
  }) {
    _emojiColor = emojiColor;
  }

  factory MoodEmojisModel.fromMap(Map<String, dynamic> map) {
    return MoodEmojisModel(
      emojiName: map['emojiName'],
      emoji: map['emoji'],
      emojiColor: Color(map['emojiColor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emojiName': emojiName,
      'emoji': emoji,
      'emojiColor': emojiColor.value,
    };
  }

  static List<MoodEmojisModel> get allMoods => [
    MoodEmojisModel(
        emojiName: 'Very Happy',
        emoji: excited,
        emojiColor: Colors.pink,
    ),
    MoodEmojisModel(
        emojiName: 'Happy',
        emoji: happy,
        emojiColor: Colors.orangeAccent,
    ),
    MoodEmojisModel(
      emojiName: 'Neutral',
      emoji: neutral,
      emojiColor: Colors.blueGrey,
    ),
    MoodEmojisModel(
        emojiName: 'Somewhat Tired',
        emoji: tired,
        emojiColor: Colors.deepPurple,
    ),
    MoodEmojisModel(
        emojiName: 'Sad',
        emoji: sad,
        emojiColor: Colors.blueAccent,
    ),
    MoodEmojisModel(
        emojiName: 'Very Sad',
        emoji: crying,
        emojiColor: Colors.lightBlue,
    ),
    MoodEmojisModel(
        emojiName: 'Angry',
        emoji: mad,
        emojiColor: Colors.deepOrange,
    ),
    MoodEmojisModel(
      emojiName: 'Very Angry',
      emoji: angry,
      emojiColor: Colors.red,
    ),
  ];

  static const String excited = '🤩';
  static const String happy = '😊';
  static const String tired = '😴';
  static const String neutral = '😐';
  static const String sad = '😢';
  static const String crying = '😭';
  static const String mad = '😠';
  static const String angry = '🤬';

  static Color getColorForMood(String moodTypeName) {
    var mood = MoodEmojisModel.allMoods.firstWhere(
            (m) => m.emojiName == moodTypeName,
        orElse: () => MoodEmojisModel.allMoods.first // Default mood if not found
    );
    return mood.emojiColor;
  }

  static MoodEmojisModel getByName(String name) {
    return allMoods.firstWhere(
          (mood) => mood.emojiName == name,
      orElse: () => allMoods.first, // Default to the first mood if not found
    );
  }

}