import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/constant.dart';
import '../../home/BottomNavBarPage.dart';
import '../data/MoodEmojisModel.dart';
import '../data/MoodEntriesModel.dart';
import 'AddNewMood.dart';
import 'EditSelectedMood.dart';

class ViewMoodLogsPage extends StatefulWidget {
  @override
  _ViewMoodLogsPageState createState() => _ViewMoodLogsPageState();
}

class _ViewMoodLogsPageState extends State<ViewMoodLogsPage>  with SingleTickerProviderStateMixin{
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? currentUser;
  List<MoodEntryModel> moodLogs = [];
  bool isLoading = true;
  String? selectedDateFilter;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchMoodLogs();
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _fetchMoodLogs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (currentUser == null) {
      setState(() {
        isLoading = false;
        moodLogs = [];
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _db.collection('moods')
          .where('userID', isEqualTo: currentUser!.uid)
          .get();

      List<MoodEntryModel> fetchedMoodLogs = snapshot.docs.map((doc) {
        return MoodEntryModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // Apply date filter
      DateTime now = DateTime.now();
      fetchedMoodLogs = fetchedMoodLogs.where((entry) {
        if (selectedDateFilter == 'Today') {
          return entry.moodDateTime.day == now.day &&
              entry.moodDateTime.month == now.month &&
              entry.moodDateTime.year == now.year;
        } else if (selectedDateFilter == 'This Week') {
          DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
          DateTime weekEnd = weekStart.add(Duration(days: 6));
          return entry.moodDateTime.isAfter(weekStart) && entry.moodDateTime.isBefore(weekEnd);
        } else if (selectedDateFilter == 'This Month') {
          return entry.moodDateTime.month == now.month && entry.moodDateTime.year == now.year;
        }
        // 'All Time' or null filter
        return true;
      }).toList();

      setState(() {
        moodLogs = fetchedMoodLogs;
        isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load mood logs: $e');
      setState(() {
        isLoading = false;
        moodLogs = [];
      });
    }
  }

  Future<void> _refreshMoodEntries() async {
    try {
      await _fetchMoodLogs();
    } catch (e) {
      print("Error refreshing mood entries: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mood Log",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: pShadeColor4,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white,),
        ),
      ),
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
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
        child: Column(
          children: [
            _buildDateFilter(),
            Expanded(child: isLoading ? CircularProgressIndicator() : _buildMoodLogList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddNewMoodPage when FAB is pressed
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddNewMoodPage(
                  onMoodSelected:(MoodEmojisModel mood) {
                    // Handle mood selection if needed
                  },
            )),
          ).then((_) => _refreshMoodEntries());
        },
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor: pShadeColor4,
      ),
    );
  }

  Widget _buildDateFilter() {
    return DropdownButton<String>(
      value: selectedDateFilter,
      onChanged: (newValue) {
        setState(() {
          selectedDateFilter = newValue;
          _fetchMoodLogs();
        });
      },
      items: <String>['Today', 'This Week', 'This Month', 'All Time']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildMoodLogList() {
    if (moodLogs.isEmpty) {
      return Center(child: Text('No mood logs found for selected filter.'));
    }
    return ListView.builder(
      itemCount: moodLogs.length,
      itemBuilder: (context, index) {
        return MoodEntryTile(
            moodEntry: moodLogs[index],
          onMoodDeleted: _refreshMoodEntries,
        );
      },
    );
  }
}

class MoodEntryTile extends StatelessWidget {
  final MoodEntryModel moodEntry;
  final Function onMoodDeleted;

  MoodEntryTile({required this.moodEntry, required this.onMoodDeleted});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(moodEntry.moodEntryID), // Unique key for Dismissible
      background: slideRightBackground(),
      secondaryBackground: slideLeftBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Handle Delete
          _deleteMoodEntry(context, moodEntry.moodEntryID);
          return false; // Dismissed automatically after delete
        } else if (direction == DismissDirection.startToEnd) {
          // Handle Edit
          _editMoodEntry(context, moodEntry.moodEntryID);
          return false; // Do not dismiss automatically
        }
        return false;
      },
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Text(
            moodEntry.moodType.emoji,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          title: Text(
            moodEntry.moodTypeName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pShadeColor8,
            ),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy – hh:mm a').format(moodEntry.moodDateTime)),
          trailing: moodEntry.notes != null ? Icon(Icons.note) : null,
          onTap: () {
            // Display notes in a dialog or a new screen when the ListTile is tapped
            if (moodEntry.notes != null && moodEntry.notes!.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Notes"),
                    content: Text(moodEntry.notes!),
                    actions: <Widget>[
                      TextButton(
                        child: Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
  Widget slideRightBackground() {
    return Container(
      color: Colors.green,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 20),
            Icon(Icons.edit, color: Colors.white),
            Text(" Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(Icons.delete, color: Colors.white),
            Text(" Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 20),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  void _editMoodEntry(BuildContext context, String moodEntryId) {
    // Navigate to the EditMoodPage with the selected moodEntryId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMoodPage(moodEntryID: moodEntryId),
      ),
    ).then((_) => onMoodDeleted());
  }


  void _deleteMoodEntry(BuildContext context, String moodEntryId) async {
    // Show a confirmation dialog before deleting
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this entry?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false), // Dismisses the dialog without deletion
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () => Navigator.of(context).pop(true), // Confirms deletion
            ),
          ],
        );
      },
    ) ?? false; // The dialog returns false if cancelled

    if (confirmDelete) {
      try {
        // Delete the mood entry from Firestore
        await FirebaseFirestore.instance.collection('moods').doc(moodEntryId).delete();

        // Optionally, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Mood entry deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
        onMoodDeleted();
      } catch (e) {
        // Handle errors, for example, by showing an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete mood entry: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}