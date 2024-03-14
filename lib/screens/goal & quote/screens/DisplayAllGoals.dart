import 'package:animated_background/animated_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/AddNewGoalPage.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model data/GoalModel.dart';
import 'DisplaySelectedGoal.dart';
import 'QuotesPage.dart';
import 'UpdateSelectedGoal.dart';
import 'package:flutter/widgets.dart';

class DisplayAllGoalsPage extends StatefulWidget {
  final int initialTabIndex;

  DisplayAllGoalsPage({this.initialTabIndex = 0});

  @override
  _DisplayAllGoalsPageState createState() => _DisplayAllGoalsPageState();
}

class _DisplayAllGoalsPageState extends State<DisplayAllGoalsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot>? _completedGoalsStream;
  late Stream<QuerySnapshot>? _uncompletedGoalsStream;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _initializeStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeStreams() async {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _userId = user.uid;  // Store the userId
      _refreshCompletedGoals(_userId);
      _refreshUncompletedGoals(_userId);
    }
  }

  void _refreshCompletedGoals(String userId) {
    _completedGoalsStream = _firestore.collection('goals')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: GoalStatus.completed.name)
        .snapshots();
  }

  void _refreshUncompletedGoals(String userId) {
    _uncompletedGoalsStream = _firestore.collection('goals')
        .where('userId', isEqualTo: userId)
        .where('status', isNotEqualTo: GoalStatus.completed.name)
        .snapshots();
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      await _firestore.collection('goals').doc(goalId).delete();
      // Instead of refreshing all goals, consider updating only the relevant stream
      if (_tabController.index == 0) {
        _refreshUncompletedGoals(_userId);
      } else {
        _refreshCompletedGoals(_userId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting goal: $e')));
    }
  }

  void _showDeleteConfirmation(String goalId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Goal'),
          content: Text('Are you sure you want to delete this goal?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteGoal(goalId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method for Completed Goals
  Widget _completedGoalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _completedGoalsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No completed goals found'));
        }

        List<GoalModel> goals = snapshot.data!.docs
            .map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((goal) => goal.progress == 100)
            .toList();

        return ListView.builder(
          itemCount: goals.length,
          itemBuilder: (context, index) {
            GoalModel goal = goals[index];
            Color cardColor = goal.getPriorityColor();
            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text(goal.title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Completed on: ${goal.dueDate != null ? DateFormat('dd/MM/yyyy').format(goal.dueDate!) : 'No completion date'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateSelectedGoalPage(goalId: goal.goalId,  refreshGoalsCallback: _initializeStreams,),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(goal.goalId),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplaySelectedGoalPage(goalId: goal.goalId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Method for Uncompleted Goals
  Widget _uncompletedGoalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _uncompletedGoalsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No uncompleted goals found'));
        }

        List<GoalModel> goals = snapshot.data!.docs
            .map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((goal) => goal.progress < 100)
            .toList();

        return ListView.separated(
          itemCount: goals.length,
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            GoalModel goal = goals[index];
            Color cardColor = goal.getPriorityColor();
            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: cardColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text('${goal.progress.toInt()}%'),
                ),
                title: Text(goal.title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due Date: ${goal.dueDate != null ? DateFormat('dd/MM/yyyy').format(goal.dueDate!) : 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusIcon(goal.status),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(goal.goalId),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateSelectedGoalPage(
                                goalId: goal.goalId,
                              refreshGoalsCallback: _initializeStreams,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplaySelectedGoalPage(goalId: goal.goalId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: const Text(
          "FastTrack Your Success!",
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
              MaterialPageRoute(builder: (context) => BottomNavBarPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white,),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold, // Style for selected tab labels
            color: Colors.white,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal, // Style for unselected tab labels
            color: Colors.white.withOpacity(0.7),
          ),
          tabs: [
            Tab(text: 'Uncompleted Goal'),
            Tab(text: 'Completed Goal'),
          ],
          indicatorColor: pShadeColor5,
          indicatorWeight: 4.0,
        ),
      ),
      body: AnimatedBackground(
        behaviour:  RandomParticleBehaviour(
          options: ParticleOptions(
            spawnMaxRadius: 50,
            spawnMaxSpeed: 50,
            particleCount: 68,
            spawnMinSpeed: 10,
            minOpacity: 0.3,
            spawnOpacity: 0.4,
            baseColor: pShadeColor2,
          ),
        ),
        vsync: this,
        child: TabBarView(
          controller: _tabController,
          children: [
            _uncompletedGoalsList(), // Widget for Uncompleted Goals
            _completedGoalsList(), // Widget for Completed Goals
          ],
        ),
      ),
    floatingActionButton: Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            heroTag: "uniqueTag1",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddNewGoalPage(),
                ),
              );
            },
            child: Icon(Icons.add, color: Colors.white,),
            backgroundColor: pShadeColor4,
          ),
        ),
        FloatingActionButton(
          heroTag: "uniqueTag2", // Different unique tag for this button
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QuotesScreen()), // Navigate to Quotes Screen
            );
          },
          child: Icon(Icons.format_quote),
          backgroundColor: pShadeColor1, // Custom color for quotes FAB
        ),
      ],
    ),
    );
  }
  Widget _buildStatusIcon(GoalStatus status) {
    IconData iconData;
    Color color;

    switch (status) {
      case GoalStatus.active:
        iconData = Icons.play_arrow;
        color = Colors.green;
        break;
      default:
        iconData = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(iconData, color: color);
  }
}

