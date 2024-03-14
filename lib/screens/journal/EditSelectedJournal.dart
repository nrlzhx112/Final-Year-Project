import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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

class EditJournalEntryForm extends StatefulWidget {
  final String entryId;

  EditJournalEntryForm({required this.entryId});

  @override
  _EditJournalEntryFormState createState() => _EditJournalEntryFormState();
}

class _EditJournalEntryFormState extends State<EditJournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final ImagePicker _picker = ImagePicker();
  List<String>? _existingImageFiles; // For existing images
  List<XFile>? _newImageFiles; // For new images

  Color currentBackgroundColor = backgroundColors; // Default background color

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _existingImageFiles = [];
    _newImageFiles = [];
    _loadJournalEntry();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<String> getDownloadURL(String imagePath) async {
    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error fetching image URL: $e');
      // Handle the error, perhaps by logging or showing a message
      return ''; // Returning an empty string or a placeholder URL
    }
  }

  Future<void> _loadJournalEntry() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference entryRef = FirebaseFirestore.instance.collection('journals').doc(userId).collection('entries').doc(widget.entryId);

      var doc = await entryRef.get();
      if (doc.exists) {
        var journalEntry = JournalEntryData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _titleController.text = journalEntry.title;
        _descriptionController.text = journalEntry.description;
        _tagsController.text = journalEntry.tags.join(',');
        setState(() {
          _selectedDate = journalEntry.date;
          _selectedTime = journalEntry.time;
          currentBackgroundColor = journalEntry.backgroundColor;
          _existingImageFiles = journalEntry.images.cast<String>();
        });
      }
    } on FirebaseAuthException catch (authError) {
      // Handle Firebase authentication errors
      print('FirebaseAuth error: ${authError.message}');
    } on FirebaseException catch (firebaseError) {
      // Handle general Firebase errors
      print('Firebase error: ${firebaseError.message}');
    } catch (e) {
      // Handle other types of errors
      print('Error loading journal entry: $e');
    }
  }



  void changeColor(Color color) {
    setState(() => currentBackgroundColor = color);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(source: source);
      if (selected != null) {
        setState(() {
          _newImageFiles = [...?_newImageFiles, selected];
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

  // Updated _deleteImage function
  Future<void> _deleteImage(int index, bool isNewImage) async {
    setState(() {
      if (isNewImage) {
        _newImageFiles?.removeAt(index);
      } else {
        _existingImageFiles?.removeAt(index); // Remove the type check
      }
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

  // Save journal entry data to Firestore with optimization
  Future<void> _saveJournal(String? journalId) async {
    if (_titleController.text.isEmpty) {
      _showErrorMessage('Title cannot be empty.');
      return;
    }

    DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute);
    if (selectedDateTime.isAfter(now)) {
      _showErrorMessage('Future date and time cannot be selected.');
      return;
    }

    List<String> tagsList = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
    if (tagsList.isEmpty || tagsList.any((tag) => !tag.startsWith('#')) || tagsList.length > 10) {
      _showErrorMessage('Tags validation failed.');
      return;
    }

    // Get user ID
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      _showErrorMessage('User is not authenticated.');
      return;
    }

    List<String> newImageUrls = [];
    if (_newImageFiles != null && _newImageFiles!.isNotEmpty) {
      newImageUrls = await uploadImages(_newImageFiles!.map((xFile) => File(xFile.path)).toList());
    }

    // Combine existing and new image URLs
    List<String> allImageUrls = [
      if (_existingImageFiles is List<String>) ...?_existingImageFiles,
      ...newImageUrls, // These are URLs of newly uploaded images (Strings)
    ];

    // Create an updated journal entry object
    JournalEntryData updatedJournal = JournalEntryData(
      title: _titleController.text,
      description: _descriptionController.text,
      tags: _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
      time: _selectedTime,
      date: _selectedDate,
      images: allImageUrls,
      backgroundColor: currentBackgroundColor,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      id: widget.entryId, // Use the existing entry ID
    );

    // Update the journal entry in Firestore
    try {
      await _db.collection('journals').doc(updatedJournal.userId)
          .collection('entries').doc(widget.entryId)
          .update(updatedJournal.toMap());

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showErrorMessage('Failed to save journal entry: $e');
    }
    // After successful update
    setState(() {
      _existingImageFiles = [...?_existingImageFiles, ...newImageUrls];
      _newImageFiles = []; // Clear new images list after merging
    });
  }

  // Method to display error messages
  void _showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Upload images in parallel and return the URLs
  Future<List<String>> uploadImages(List<File> images) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    var uploadTasks = images.map((image) async {
      try {
        String fileName = Path.basename(image.path);
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref('journalImages/$userId/$fileName'); // Correct path

        var uploadTask = ref.putFile(image);
        var taskSnapshot = await uploadTask;
        return await taskSnapshot.ref.getDownloadURL();
      } catch (e) {
        print('Error uploading image: $e');
        return '';
      }
    }).toList();

    var imageUrls = await Future.wait(uploadTasks);
    return imageUrls.where((url) => url.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Journal Entry",
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
              // Add buttons for picking images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text("Pick from Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pShadeColor2, // Use your color
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.image),
                    label: Text("Pick from Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pShadeColor2, // Use your color
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildImageDisplaySection(_existingImageFiles, false),
              _buildImageDisplaySection(_newImageFiles, true),
              SizedBox(height: 30),
              // Added space between images and submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplaySection(List<dynamic>? images, bool isNewImage) {
    if (images == null || images.isEmpty) {
      return SizedBox.shrink(); // or some other widget that represents an empty state
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: images.asMap().entries.map((entry) {
          int index = entry.key;
          var image = entry.value;

          Widget imageWidget = isNewImage
              ? Image.file(File(image.path), width: 250, height: 250, fit: BoxFit.cover)
              : CachedNetworkImage(
            imageUrl: image,
            width: 250,
            height: 250,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          );

          return Padding(
            padding: EdgeInsets.all(8),
            child: Stack(
              children: [
                imageWidget,
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _deleteImage(index, isNewImage),
                    child: Icon(Icons.remove_circle, color: Colors.red, size: 30),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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