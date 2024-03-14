import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/journal/DisplayAllJournal.dart';
import 'package:emindmatterssystem/screens/journal/JournalEntryModel.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as Path;

class JournalEntryForm extends StatefulWidget {
  @override
  _JournalEntryFormState createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;

  Color currentBackgroundColor = backgroundColors; // Default background color

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void changeColor(Color color) {
    setState(() => currentBackgroundColor = color);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(source: source);
      if (selected != null) {
        setState(() {
          _imageFiles = [...?_imageFiles, selected];
        });
      }
    } catch (e) {
      // Handle errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteImage(int index) async {
    setState(() {
      _imageFiles?.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900), // Adjust as needed
      lastDate: DateTime(
          now.year, now.month, now.day), // Current date as the last date
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Convert the selected date to the desired format
      String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
      print(formattedDate); // You can print or use this formattedDate as needed
    }
  }


  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.hour < now.hour ||
        (picked.hour == now.hour && picked.minute <= now.minute))) {
      setState(() {
        _selectedTime = picked;
      });
    } else {
      // Optionally show a message if a future time is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Future time cannot be selected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload images in parallel and return the URLs
  Future<List<String>> uploadImages(List<File> images) async {
    var uploadTasks = images.map((image) async {
      String fileName = Path.basename(image.path);
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref('journalImages/${FirebaseAuth.instance.currentUser!.uid}/$fileName');

      var uploadTask = ref.putFile(image);
      var imageUrl = await (await uploadTask).ref.getDownloadURL();
      return imageUrl;
    }).toList();

    return Future.wait(uploadTasks);
  }

  // Save journal entry data to Firestore with optimization
  Future<void> _saveJournal(String? journalId) async {
    // Input validation
    if (_titleController.text.isEmpty) {
      _showErrorMessage('Title cannot be empty.');
      return;
    }

    DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    if (selectedDateTime.isAfter(now)) {
      _showErrorMessage('Future date and time cannot be selected.');
      return;
    }

    List<String> tagsList = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
    if (tagsList.isEmpty || tagsList.any((tag) => !tag.startsWith('#')) || tagsList.length > 10) {
      _showErrorMessage('Tags validation failed.');
      return;
    }

    List<String> imageUrls = [];
    if (_imageFiles != null) {
      List<File> imageFiles = _imageFiles?.map((xFile) => File(xFile.path)).toList() ?? [];
      imageUrls = await uploadImages(imageFiles);
    }

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        _showErrorMessage('User is not authenticated.');
        return;
      }

      JournalEntryData journal = JournalEntryData(
        title: _titleController.text,
        description: _descriptionController.text,
        tags: tagsList,
        time: _selectedTime,
        date: _selectedDate,
        images: imageUrls,
        backgroundColor: currentBackgroundColor,
        userId: userId,
        id: journalId ?? generateUniqueId(), // Use the generateUniqueId method for new entries
      );

      DocumentReference userJournalRef = _db.collection('journals').doc(userId);

      if (journalId == null) {
        // Add a new journal entry to the user's 'entries' sub-collection
        var docRef = await userJournalRef.collection('entries').add(journal.toMap());
        Navigator.pop(context, JournalEntryData.fromMap(journal.toMap(), docRef.id));
      } else {
        // Update an existing journal entry in the user's 'entries' sub-collection
        await userJournalRef.collection('entries').doc(journalId).update(journal.toMap());
        Navigator.pop(context, journalId);
      }
    } catch (e) {
      _showErrorMessage('Failed to save journal entry: $e');
    }
  }

  void _showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create New Journal",
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
              MaterialPageRoute(builder: (context) => JournalListView()),
            );
          },
          icon: Icon(Icons.close, color: Colors.white,),
        ),
      ),
      body: Container(
        color: currentBackgroundColor, // Set the container's color
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                // Allows for unlimited lines
                keyboardType: TextInputType.multiline,
                // Set keyboard type to multiline
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one tag';
                  }

                  // Split the tags by commas
                  List<String> tags = value.split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty) // Remove empty tags
                      .toList();

                  // Ensure each tag starts with '#'
                  if (tags.any((tag) => !tag.startsWith('#'))) {
                    return 'Each tag must start with "#"';
                  }

                  // Optional: Limit the number of tags
                  if (tags.length > 5) {
                    return 'You can enter up to 10 tags';
                  }

                  // Optional: Check for special characters
                  RegExp regExp = RegExp(r'^[a-zA-Z0-9, ]+$');
                  if (!tags.every((tag) => regExp.hasMatch(tag))) {
                    return 'Tags can only contain alphanumeric characters and commas';
                  }

                  return null;
                },
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text("Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate.toLocal())}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text("Time: ${_selectedTime.format(context)}"),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              SizedBox(height: 20),
              _buildColorPickerButton(),
              // Button to open color picker
              SizedBox(height: 20),
              _buildImagePickerSection(),
              SizedBox(height: 30),
              // Added space between images and submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerButton() {
    return ElevatedButton(
      child: Text(
        'Select Background Color',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Pick a color!'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: currentBackgroundColor,
                  onColorChanged: changeColor,
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Got it'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pShadeColor4,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: pShadeColor4,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: Icon(Icons.camera),
              label: Text("Camera"),
              style: ElevatedButton.styleFrom(backgroundColor: pShadeColor1),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: Icon(Icons.image),
              label: Text("Gallery"),
              style: ElevatedButton.styleFrom(backgroundColor: pShadeColor1),
            ),
          ],
        ),
        SizedBox(height: 10),
        _imageFiles != null && _imageFiles!.isNotEmpty
            ? Wrap(
          spacing: 10,
          runSpacing: 10, // Added spacing between rows of images
          children: _imageFiles!.asMap().entries.map((entry) {
            int index = entry.key;
            XFile file = entry.value;
            return Stack(
              children: [
                Image.file(
                  File(file.path),
                  width: MediaQuery.of(context).size.width * 1.5,
                  height: MediaQuery.of(context).size.width * 1.5,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _deleteImage(index),
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 12,
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        )
            : Text('No images selected.'),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        await _saveJournal(null); // Assuming you are creating a new goal
      },
      child: Text(
        'Submit',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: pShadeColor4,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }
}

// Custom method to generate a unique ID
String generateUniqueId() {
  var now = DateTime.now();
  var timestamp = now.millisecondsSinceEpoch;
  var userId = FirebaseAuth.instance.currentUser!.uid;
  return '$userId-$timestamp';
}