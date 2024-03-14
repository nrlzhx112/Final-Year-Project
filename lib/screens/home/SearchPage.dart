
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import '../goal & quote/model data/GoalModel.dart';
import '../goal & quote/screens/DisplayAllGoals.dart';
import '../journal/DisplayAllJournal.dart';
import '../journal/JournalEntryModel.dart';
import '../user/UserModel.dart';
import '../user/ViewOtherUserProfile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController searchController;
  List<dynamic> searchResults = [];
  bool isSubmitted = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _getCurrentUserId() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      _userId = user.uid;
    }
  }

  Future<List<Map<String, dynamic>>> _getUserSearchResults(String query) async {
    List<Map<String, dynamic>> results = [];

    // Search by username
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + '\uf8ff')
        .get();
    results.addAll(snapshot.docs.map((doc) {
      Map<String, dynamic> data = UserModel.fromDocument(doc).toJson();
      data['type'] = 'user';
      return data;
    }).toList());

    QuerySnapshot<Map<String, dynamic>> emailsnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query)
        .get();
    results.addAll(emailsnapshot.docs.map((doc) {
      Map<String, dynamic> data = UserModel.fromDocument(doc).toJson();
      data['type'] = 'user';
      return data;
    }).toList());

    // Search journals by title
    QuerySnapshot<Map<String, dynamic>> titleSnapshot = await FirebaseFirestore.instance
        .collection('journals')
        .doc(_userId)
        .collection('entries')
        .where('title',  isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + '\uf8ff')
        .get();
    results.addAll(titleSnapshot.docs.map((doc) {
      Map<String, dynamic> data = JournalEntryData.fromMap(doc.data() as Map<String, dynamic>, doc.id).toMap();
      data['type'] = 'journal';
      return data;
    }).toList());

    // Search journals by tags
    QuerySnapshot<Map<String, dynamic>> tagsSnapshot = await FirebaseFirestore.instance
        .collection('journals')
        .doc(_userId)
        .collection('entries')
        .where('tags', arrayContains: query)
        .get();
    results.addAll(tagsSnapshot.docs.map((doc) {
      Map<String, dynamic> data = JournalEntryData.fromMap(doc.data() as Map<String, dynamic>, doc.id).toMap();
      data['type'] = 'journal';
      return data;
    }).toList());

    // Search completed and uncompleted goals by title
    QuerySnapshot<Map<String, dynamic>> goalsSnapshot = await FirebaseFirestore.instance
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + '\uf8ff')
        .get();
    results.addAll(goalsSnapshot.docs.map((doc) {
      Map<String, dynamic> data = GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toMap();
      data['type'] = 'goal';
      return data;
    }).toList());

    // Search topics by title
    QuerySnapshot<Map<String, dynamic>> titleTopicsSnapshot = await FirebaseFirestore.instance
        .collection('topics')
        .where('title',  isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + '\uf8ff')
        .get();
    results.addAll(titleTopicsSnapshot.docs.map((doc) {
      return doc.data()..['type'] = 'topic';
    }).toList());

    // Search topics by author
    QuerySnapshot<Map<String, dynamic>> authorSnapshot = await FirebaseFirestore.instance
        .collection('topics')
        .where('author', isEqualTo: query)
        .get();
    results.addAll(authorSnapshot.docs.map((doc) {
      return doc.data()..['type'] = 'topic';
    }).toList());

    // Search help crisis by name
    QuerySnapshot<Map<String, dynamic>> crisisNameSnapshot = await FirebaseFirestore.instance
        .collection('helpCrisis')
        .where('name',  isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .get();
    results.addAll(crisisNameSnapshot.docs.map((doc) {
      return doc.data()..['type'] = 'crisis';
    }).toList());

    // Search help crisis by author
    QuerySnapshot<Map<String, dynamic>> crisisAuthorSnapshot = await FirebaseFirestore.instance
        .collection('helpCrisis')
        .where('author', isEqualTo: query)
        .get();
    results.addAll(crisisAuthorSnapshot.docs.map((doc) {
      return doc.data()..['type'] = 'crisis';
    }).toList());

    return results;
  }

  Widget _noResults(IconData icon, String input) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FaIcon(icon, size: 30,),
          Padding(padding: EdgeInsets.only(top: 5, bottom: 5)),
          Text(input, style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: pShadeColor1,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(horizontal: 15),
          padding: EdgeInsets.only(left: 15),
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.search, color: pShadeColor9),
              ),
              Expanded(
                child: TextField(
                  controller: searchController,
                  cursorColor: pShadeColor6,
                  cursorHeight: 20,
                  autofocus: true,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    var results = await showDialog(
                      context: context,
                      builder: (context) => FutureProgressDialog(_getUserSearchResults(value)),
                    );
                    setState(() {
                      searchResults = results;
                      isSubmitted = true;
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: pShadeColor9,),
                onPressed: () {
                  setState(() {
                    isSubmitted = false;
                    searchController.clear();
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: isSubmitted && searchResults.isEmpty
              ? _noResults(FontAwesomeIcons.hourglass, "No users found..")
              : Container(),
        ),
      ],
    );
  }

  Widget _buildCombinedSearchResultList() {
    if (searchResults.isEmpty) {
      return Center(child: Text("No results found."));
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        var item = searchResults[index];

        // Determine the type of the item using the 'type' field
        switch (item['type']) {
          case 'user':
            var userData = UserModel.fromJson(item);
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userData.photoUrl ?? ''),
              ),
              title: Text(userData.username ?? ''),
              subtitle: Text(userData.email),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewOtherUserProfile(userId: userData.userId)),
                );
              },
            );
          case 'journal':
            var journalData = JournalEntryData.fromMap(item, item['id']);
            return ListTile(
              title: Text(journalData.title),
              subtitle: Wrap(
                spacing: 6,
                children: (journalData.tags).map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: pShadeColor4.withOpacity(0.3),
                )).toList(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JournalListView()),
                );
              },
            );
          case 'goal':
            var goalData = GoalModel.fromMap(item, item['goalId'] ?? 'defaultGoalId');
            return ListTile(
              title: Text(goalData.title),
              subtitle: Text('Status: ${goalData.status.name}'),
              onTap: () {
                if (goalData.goalId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DisplayAllGoalsPage(initialTabIndex: goalData.status == GoalStatus.completed ? 1 : 0)),
                  );
                } else {
                  // Handle the case where goalId is not available
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Goal ID is not available.")));
                }
              },
            );
        }

        // Default return (this should never be reached if searchResults is correctly populated)
        return Container();
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        elevation: 0,
        leading: IconButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16),
            _buildSearchBar(),
            Expanded(
              child: isSubmitted ? _buildCombinedSearchResultList(): Container(),
            ),
          ],
        ),
      ),
    );
  }
}

