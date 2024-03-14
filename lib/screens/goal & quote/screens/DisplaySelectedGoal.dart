import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/DisplayAllGoals.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model data/GoalModel.dart';

class DisplaySelectedGoalPage extends StatefulWidget {
  final String goalId;

  DisplaySelectedGoalPage({Key? key, required this.goalId}) : super(key: key);

  @override
  _DisplaySelectedGoalPageState createState() => _DisplaySelectedGoalPageState();
}

class _DisplaySelectedGoalPageState extends State<DisplaySelectedGoalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoalModel? goalDetails;

  @override
  void initState() {
    super.initState();
    _fetchGoalDetails();
  }

  Future<void> _fetchGoalDetails() async {
    try {
      DocumentSnapshot goalSnapshot = await _firestore.collection('goals').doc(widget.goalId).get();
      if (goalSnapshot.exists) {
        setState(() {
          goalDetails = GoalModel.fromMap(goalSnapshot.data() as Map<String, dynamic>, goalSnapshot.id);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching goal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = goalDetails?.getPriorityColor() ?? backgroundColors; // Default to white if goalDetails is null
    if (goalDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Goal Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: const Text(
          "View Goal",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DisplayAllGoalsPage()),
            );
          },
          icon: Icon(Icons.close, color: Colors.white,),
        ),
      ),
      // Update the Scaffold background color based on the selected priority
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDetailRow('Title:', goalDetails!.title, Icons.title),
                _buildDetailRow('Notes:', goalDetails!.notes ?? 'No notes', Icons.note),
                _buildDetailRow('Start Date:', _formatDate(goalDetails!.startDate), Icons.calendar_today),
                _buildDetailRow('Due Date:', _formatDate(goalDetails!.dueDate), Icons.calendar_today),
                _buildDetailRow('Status:', goalDetails!.status.name, Icons.check_circle),
                _buildDetailRow('Priority:', goalDetails!.priority.name, Icons.priority_high),
                SizedBox(height: 20,),
                _buildProgressIndicator(goalDetails!.progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData iconData, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: Colors.blueGrey,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded( // Wrap in an Expanded widget to utilize available space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.normal, // Adjust font weight if needed
                  ),
                  softWrap: true, // Enable text wrapping
                  overflow: TextOverflow.visible, // Ensure all text is visible
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressIndicator(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueGrey),
          ),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(pShadeColor4),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.star,
              color: pShadeColor4,
              size: 24,
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }


  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : 'N/A';
  }
}
