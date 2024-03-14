import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/auth/LoginPage.dart';
import 'package:emindmatterssystem/screens/mood/pages/ViewMoodLogsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/constant.dart';
import '../data/MoodEmojisModel.dart';
import '../data/MoodEntriesModel.dart';

class EditMoodPage extends StatefulWidget {
  final String moodEntryID;

  EditMoodPage({Key? key, required this.moodEntryID}) : super(key: key);

  @override
  _EditMoodPageState createState() => _EditMoodPageState();
}

class _EditMoodPageState extends State<EditMoodPage> {
  DateTime _selectedDateTime = DateTime.now();
  MoodEmojisModel? selectedMood;
  TextEditingController _notesController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isNotesValid = true;
  late User? _currentUser; // Declare a user variable

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      _showLoginErrorMessage();
    } else {
      _fetchMoodEntryById(widget.moodEntryID).then((moodEntry) {
        if (moodEntry != null) {
          setState(() {
            selectedMood = MoodEmojisModel.getByName(moodEntry.moodTypeName);
            _notesController.text = moodEntry.notes ?? ''; // Use an empty string if notes are null
            _selectedDateTime = moodEntry.moodDateTime;
          });
        }
      });
    }
  }

  void _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000), // Set an appropriate start date
      lastDate: DateTime(2100),  // Set an appropriate end date
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = pickedDateTime;
        });
      }
    }
  }

  void _showLoginErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You need to be logged in to access this page.'),
        action: SnackBarAction(
          label: 'LOGIN',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
    );
  }

  void _validateNotes(String value) {
    setState(() {
      _isNotesValid = value.length <= 135;
    });
  }

  Future<MoodEntryModel?> _fetchMoodEntryById(String moodEntryID) async {
    try {
      DocumentSnapshot snapshot = await _db.collection('moods').doc(moodEntryID).get();
      if (snapshot.exists) {
        MoodEntryModel moodEntry = MoodEntryModel.fromMap(snapshot.data() as Map<String, dynamic>);
        if (_currentUser != null && moodEntry.userID == _currentUser!.uid) {
          return moodEntry;
        }
      }
    } catch (e) {
      print("Error fetching mood entry: $e");
      _showErrorMessage("Error loading mood data. Please try again.");
    }
    return null;
  }


  Future<void> _updateMood() async {
    try {
      _showLoadingDialog(); // Display loading dialog

      // Check if the current user is authorized to update this mood entry
      if (_currentUser?.uid != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('moods')
            .doc(widget.moodEntryID)
            .get();

        if (snapshot.exists) {
          MoodEntryModel moodEntry = MoodEntryModel.fromMap(snapshot.data() as Map<String, dynamic>);

          // Ensure the current user is the owner of the mood entry
          if (moodEntry.userID == _currentUser!.uid) {
            await _db.collection('moods').doc(widget.moodEntryID).update({
              'moodDateTime': _selectedDateTime,
              'moodTypeName': selectedMood!.emojiName,
              'notes': _notesController.text.trim(),
              'userID': _currentUser!.uid,
            });

            _showSuccessMessage('Mood updated successfully!');
            Navigator.of(context).pop();
            _navigateToMoodTrackingPage();
          }
        }
      }
    } catch (e) {
      print('Error updating mood data: $e');
      _showErrorMessage('Failed to update mood. Please try again.');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  void _navigateToMoodTrackingPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ViewMoodLogsPage()),
    );
  }

  void _showSuccessMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void onMoodSelected(MoodEmojisModel mood) {
    setState(() {
      selectedMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            IgnorePointer(
              ignoring: true, // Set this to true to ignore pointer events
              child: ViewMoodLogsPage(),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Adjust sigmaX and sigmaY for desired blur intensity
              child: Container(
                color: Colors.transparent, // This ensures the container is transparent
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(
                      35.0,
                    ),
                    topRight: Radius.circular(
                      35.0,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _selectDateTime(context),
                            icon: const Icon(Icons.calendar_month_outlined),
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Adjust padding as needed
                              ),
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy hh:mm a').format(_selectedDateTime),
                                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), // Increase font size
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: MoodEmojisModel.allMoods.map(
                                (mood) => GestureDetector(
                              onTap: () => onMoodSelected(mood), // Updated here
                              child: MoodOption(
                                moodEmoji: mood,
                                isSelected: selectedMood?.emojiName == mood.emojiName,
                                onTap: onMoodSelected,
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Add a notes",
                          errorText: _isNotesValid ? null : 'Notes can only 135 character of words',
                        ),
                        maxLines: null,
                        onChanged: (value) => _validateNotes(value),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding here
                            child: ElevatedButton(
                              onPressed: () {
                                _navigateToMoodTrackingPage();
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pShadeColor4,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding here
                            child: ElevatedButton(
                              onPressed: () {
                                _updateMood();
                              },
                              child: const Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pShadeColor4,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodOption extends StatelessWidget {
  final MoodEmojisModel moodEmoji;
  final bool isSelected;
  final Function(MoodEmojisModel) onTap; // Callback to notify when a mood is selected

  MoodOption({
    required this.moodEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(moodEmoji), // Call the onTap callback when tapped
      child: Container(
        margin: EdgeInsets.all(8.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? moodEmoji.emojiColor.withOpacity(0.5) : moodEmoji.emojiColor,
        ),
        child: Text(
          moodEmoji.emoji,
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
