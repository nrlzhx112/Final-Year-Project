import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, completed }
enum GoalPriority { high, medium, low }

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class GoalModel {
  String goalId;
  final String title;
  final String? notes;
  final DateTime? startDate;
  final DateTime? _dueDate;
  final String userId;
  GoalStatus status;
  final GoalPriority priority;
  double progress; // New field for progress percentage

  GoalModel({
    this.goalId = '',
    required this.title,
    this.notes,
    DateTime? startDate, // Accepting startDate as a parameter
    DateTime? dueDate,
    required this.userId,
    required this.status,
    required this.priority,
    this.progress = 0.0,
  })  : startDate = startDate,
        _dueDate = dueDate {
    // Validate that dueDate is after startDate if both are provided
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      throw ArgumentError('Due date must be after start date.');
    }
    if (progress < 0 || progress > 100) {
      throw ArgumentError('Progress must be between 0 and 100.');
    }
    status = _determineStatusBasedOnProgress(); // Set status based on progress
  }

  GoalStatus _determineStatusBasedOnProgress() {
    return progress >= 100 ? GoalStatus.completed : GoalStatus.active;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
      'userId': userId,
      'status': status.name,
      'priority': priority.name,
      'progress': progress,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    return GoalModel(
      goalId: id,
      title: map['title'] ?? 'Untitled', // Provide a default value if null
      notes: map['notes'],
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      userId: map['userId'] ?? '', // Provide a default value if null
      status: map['status'] != null ? GoalStatus.values.byName(map['status']) : GoalStatus.active, // Default to active if null
      priority: map['priority'] != null ? GoalPriority.values.byName(map['priority']) : GoalPriority.low, // Default to low if null
      progress: map['progress']?.toDouble() ?? 0.0, // Default to 0.0 if null
    );
  }

  DateTime? get dueDate => _dueDate;

  Color getPriorityColor() {
    switch (priority) {
      case GoalPriority.high:
        return Colors.red.shade200;
      case GoalPriority.medium:
        return Colors.orange.shade200;
      case GoalPriority.low:
        return Colors.teal.shade200;
      default:
        return Colors.grey; // Default color
    }
  }

  // Updated logic to update progress and automatically handle goal status
  Future<void> updateProgress(double newProgress) async {
    if (newProgress < 0 || newProgress > 100) {
      throw ArgumentError('Progress must be between 0 and 100.');
    }

    // Update local model
    progress = newProgress;
    status = progress == 100.0 ? GoalStatus.completed : GoalStatus.active;

    // Update Firestore
    try {
      await _firestore.collection('goals').doc(goalId).update({
        'progress': progress,
        'status': status.name,
      });
    } catch (e) {
      // Handle or rethrow the exception as needed
      print('Error updating goal: $e');
      throw e;
    }
  }

}
