import 'dart:async';
import 'package:animated_background/animated_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/journal/EditSelectedJournal.dart';
import 'package:emindmatterssystem/screens/journal/ViewSelectedJournal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:emindmatterssystem/screens/journal/CreateNewJournalEntryForm.dart';
import 'package:emindmatterssystem/screens/journal/JournalEntryModel.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart'; // Import this for HapticFeedback

class JournalListView extends StatefulWidget {
  @override
  _JournalListViewState createState() => _JournalListViewState();
}

class _JournalListViewState extends State<JournalListView> with SingleTickerProviderStateMixin{
  List<JournalEntryData> journalEntries = [];
  bool isLoading = false;
  late StreamSubscription<QuerySnapshot> _journalSubscription;

  @override
  void initState() {
    super.initState();
    _setupJournalListener();
  }

  @override
  void dispose() {
    _journalSubscription.cancel();
    super.dispose();
  }

  void _setupJournalListener() {
    var uid = FirebaseAuth.instance.currentUser!.uid;
    _journalSubscription = FirebaseFirestore.instance.collection('journals')
        .doc(uid).collection('entries')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        journalEntries = snapshot.docs
            .map((doc) => JournalEntryData.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        isLoading = false;
      });
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: ${error.toString()}"))
      );
    });
  }

  void _onPopupMenuSelected(String value, String entryId) {
    switch (value) {
      case 'view':
        _navigateToViewPage(entryId);
        break;
      case 'edit':
        _navigateToEditPage(entryId);
        break;
      case 'delete':
        _deleteJournalEntry(entryId);
        break;
    }
  }

  void _navigateToViewPage(String entryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSelectedJournalPage(entryId: entryId),
      ),
    );
  }

  void _navigateToEditPage(String entryId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditJournalEntryForm(entryId: entryId),
      ),
    );
    if (result != null) {
      // Assuming that the edit page returns 'true' when an edit is successful
      _refreshJournals(); // Refresh journals if edit was successful
    }
  }

  Future<void> _refreshJournals() async {
    // Optionally, perform any necessary operations before refreshing
    setState(() {
      isLoading = true;
    });

    // Wait for a short delay to simulate the refresh process
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });
  }

  void _deleteJournalEntry(String entryId) async {
    try {
      var uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('journals')
          .doc(uid).collection('entries').doc(entryId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting entry: ${e.toString()}"))
      );
    }
  }

  Widget _buildJournalList() {
    return ListView.builder(
      itemCount: journalEntries.length,
      itemBuilder: (context, index) {
        final entry = journalEntries[index];
        return Slidable(
          startActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  HapticFeedback.lightImpact(); // Providing haptic feedback
                  _onPopupMenuSelected('view', entry.id);
                },
                backgroundColor: Colors.lightBlue.shade300,
                foregroundColor: Colors.white,
                icon: Icons.visibility,
                label: 'View',
                borderRadius: BorderRadius.circular(15),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  HapticFeedback.lightImpact(); // Providing haptic feedback
                  _onPopupMenuSelected('edit', entry.id);
                },
                backgroundColor: Colors.lightGreen.shade300,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                borderRadius: BorderRadius.circular(15),
              ),
              SlidableAction(
                onPressed: (context) {
                  HapticFeedback.lightImpact(); // Providing haptic feedback
                  _onPopupMenuSelected('delete', entry.id);
                },
                backgroundColor: Colors.redAccent.shade200,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: BorderRadius.circular(15),
              ),
            ],
          ),
          child: Card(
            elevation: 8,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            shadowColor: Colors.grey.shade500,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [entry.backgroundColor.withOpacity(0.5), entry.backgroundColor],
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(15),
              title: Text(
                entry.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(entry.date) + ' - ' + entry.time.format(context),
                    style: TextStyle(fontSize: 15, color: pShadeColor9),
                  ),
                  SizedBox(height: 10),
                  Text(
                    entry.description,
                    style: TextStyle(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: entry.tags
                        .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: pShadeColor4.withOpacity(0.3),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: Text(
          "Cherish memories today!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Making the text bold
          ),
          textAlign: TextAlign.center, // Centering the text
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
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
        child: RefreshIndicator(
          onRefresh: _refreshJournals, // Use the new refresh method
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : journalEntries.isEmpty
              ? Center(child: Text("No entries found"))
              : _buildJournalList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: pShadeColor4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JournalEntryForm()),
          ).then((_) => _refreshJournals());
        },
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Create New Entry',
      ),
    );
  }
}
