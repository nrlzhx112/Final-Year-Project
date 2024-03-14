import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/AddNewGoalPage.dart';
import 'package:emindmatterssystem/screens/info/TabBarInfo.dart';
import 'package:emindmatterssystem/screens/journal/DisplayAllJournal.dart';
import 'package:emindmatterssystem/screens/mood/pages/ViewMoodLogsPage.dart';
import 'package:emindmatterssystem/screens/home/SearchPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? currentUser = firebaseAuth.currentUser;
    final CollectionReference usersRef =
    FirebaseFirestore.instance.collection('users');

    // Function to show feedback dialog
    void showFeedbackDialog(BuildContext context, User? currentUser) {
      final TextEditingController feedbackController = TextEditingController();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Submit Feedback", style: TextStyle(color: pShadeColor4)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Your feedback is important to us!"),
                SizedBox(height: 20),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    hintText: "Enter your feedback here",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Submit"),
                onPressed: () async {
                  if (currentUser != null && feedbackController.text.isNotEmpty) {
                    // Get the user's username
                    final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();

                    final String username = userSnapshot.get('username') ?? '';

                    // Construct feedback data with username
                    final feedbackData = {
                      'userId': currentUser.uid,
                      'username': username,
                      'feedback': feedbackController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    };

                    // Add feedback to Firestore
                    await FirebaseFirestore.instance
                        .collection('feedbacks')
                        .add(feedbackData)
                        .then((value) => print("Feedback Added"))
                        .catchError((error) => print("Failed to add feedback: $error"));

                    // Clear the text field and close the dialog
                    feedbackController.clear();
                    Navigator.of(context).pop();
                  } else {
                    // Handle the case where feedback is empty or user is null
                    final snackBar = SnackBar(
                      content: Text('Please enter feedback before submitting.'),
                      duration: Duration(seconds: 3),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        automaticallyImplyLeading: false, // Set this to false to hide the back button
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white,),
            onPressed: () {
              // Navigate to the NotificationPage when the notification icon is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            //for design
            decoration: BoxDecoration(
              color: pShadeColor4,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(150),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  title: StreamBuilder<DocumentSnapshot>(
                    stream: usersRef.doc(currentUser?.uid ?? '').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;

                        if (data != null) {
                          final String username = data['username'] ?? '';

                          if (username.isNotEmpty) {
                            return Text(
                              'Welcome $username !',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 30.0,
                              ),
                            );
                          }
                        }
                      }
                      // Return a default widget when data is not available
                      return Text(
                        'Welcome !',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30.0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          Container(
            color: pShadeColor4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                  color: backgroundColors,
                  borderRadius:
                  BorderRadius.only(
                      topLeft: Radius.circular(300),
                  ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 15,
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 40,
                  mainAxisSpacing: 30,
                  children: [
                    itemDashboard(
                      context,
                      'More Info',
                      Icons.info,
                      pShadeColor7,
                          () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TabBarInfoPage(),
                          ),
                        );
                        // Handle Schedule onTap
                      },
                    ),
                    itemDashboard(
                      context,
                      'Goal-Settings',
                      Icons.flag,
                      pShadeColor7,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddNewGoalPage(),
                          ),
                        );
                        // Handle Pomodoro Timer onTap
                      },
                    ),
                    itemDashboard(
                      context,
                      'Mood-Tracking',
                      Icons.mood,
                      pShadeColor7,
                          () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewMoodLogsPage(),
                          ),
                        );
                        // Handle CGPA Calculator onTap
                      },
                    ),
                    itemDashboard(
                      context,
                      'Journaling',
                      Icons.book,
                      pShadeColor7,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalListView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showFeedbackDialog(context, currentUser);
        },
        child: Icon(Icons.feedback, color: Colors.white,),
        backgroundColor: pShadeColor4, // Set the color as per your theme
      ),
    );
  }

  GestureDetector itemDashboard(
      BuildContext context,
      String title,
      IconData iconData,
      Color background,
      void Function()? onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: pShadeColor1,
              spreadRadius: 3,
              blurRadius: 7,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.0, // Adjust the font size as desired
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
