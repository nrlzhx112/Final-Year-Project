import 'package:flutter/material.dart';

class JournalEntryData {
  String id;
  String title;
  String description;
  List<String> tags;
  DateTime date;
  TimeOfDay time;
  List<String> images;
  Color backgroundColor;
  String userId;

  JournalEntryData({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.date,
    required this.time,
    required this.images,
    required this.backgroundColor,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':id,
      'title': title,
      'description': description,
      'tags': tags,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'images': images,
      'backgroundColor': backgroundColor.value,
      'userId': userId,
    };
  }

  factory JournalEntryData.fromMap(Map<String, dynamic> map, String id) {
    List<String> tags = [];

    // Check if 'tags' is a List
    if (map['tags'] is List<dynamic>) {
      // Convert each element to a String
      tags = List<String>.from(map['tags'].map((tag) => tag.toString()));
    } else if (map['tags'] is String) {
      // If 'tags' is a String, split it by commas
      tags = map['tags'].split(',').map((tag) => tag.trim()).toList();
    }

    return JournalEntryData(
      id: id,
      title: map['title'],
      description: map['description'],
      tags: tags,
      date: DateTime.parse(map['date']),
      time: TimeOfDay(
        hour: int.parse(map['time'].split(':')[0]),
        minute: int.parse(map['time'].split(':')[1]),
      ),
      images: List<String>.from(map['images']),
      backgroundColor: Color(map['backgroundColor']),
      userId: map['userId'],
    );
  }

}
