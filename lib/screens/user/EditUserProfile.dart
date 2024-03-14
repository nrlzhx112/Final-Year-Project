import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:emindmatterssystem/screens/user/UserModel.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditUserProfile extends StatefulWidget {
  final UserModel user;

  EditUserProfile({required this.user});

  @override
  _EditUserProfileState createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _birthdateController;
  late TextEditingController _emailController;
  final RegExp _usernameValidator = RegExp(r'^[a-z0-9]+$'); // RegExp for lowercase letters and numbers

  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditingUsername = false;
  bool _isEditingBio = false;
  String? _photoUrl;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _birthdateController = TextEditingController();
    _bioController = TextEditingController();

    // Initialize with user's birthdate if available, else use current date
    _selectedDate = widget.user.birthdate ?? DateTime.now();

    _fetchProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete your account? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteUserAccount(); // Call the delete account function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserAccount() async {
    try {
      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .delete();

      // Delete user's authentication record
      await currentUser.delete();

      // Navigate to the welcome screen or log-in screen after successful deletion
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    } catch (e) {
      // Handle errors, e.g., show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account: $e")),
      );
    }
  }

  // Method to show DatePicker
  Future<void> _selectDate(BuildContext context) async {
    // Ensure _selectedDate is between firstDate and lastDate
    DateTime adjustedInitialDate = _selectedDate;
    DateTime firstDate = DateTime(1963);
    DateTime lastDate = DateTime(2011);

    if (_selectedDate.isBefore(firstDate)) {
      adjustedInitialDate = firstDate;
    } else if (_selectedDate.isAfter(lastDate)) {
      adjustedInitialDate = lastDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: adjustedInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await auth.FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    } catch (e) {
      print('Sign out failed: $e');
    }
  }

  Future<void> _fetchProfileData() async {
    final DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.userId)
        .get(); // Changed from .collection('userProfile').doc('profile').get();

    if (profileSnapshot.exists) {
      final userProfileData = profileSnapshot.data() as Map<String, dynamic>?;
      final photoUrl = userProfileData?['photoUrl'] as String?;
      final username = userProfileData?['username'] as String?;
      final email = userProfileData?['email'] as String?;
      final birthdate = userProfileData?['birthdate'] as String?;
      final bio = userProfileData?['bio'] as String?;

      if (username != null) {
        setState(() {
          _usernameController.text = username;
        });
      }
      if (email != null) {
        setState(() {
          _emailController.text = email;
        });
      }
      if (birthdate != null) {
        DateTime parsedDate = DateTime.tryParse(birthdate) ?? DateTime.now();
        setState(() {
          _birthdateController.text = DateFormat('yyyy-MM-dd').format(parsedDate);
          _selectedDate = parsedDate; // Update _selectedDate
        });
      }
      if (bio != null) {
        setState(() {
          _bioController.text = bio;
        });
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        setState(() {
          _photoUrl = photoUrl;
        });
      }
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );
    if (pickedImage != null) {
      setState(() {
        _photoUrl = null; // Reset the existing photo URL
        _selectedImage = File(pickedImage.path);
        _uploadUserProfilePhoto(); // Upload the selected image
      });
    }
  }

  Future<String> _uploadUserProfilePhoto() async {
    // Ensure that the current user is authenticated
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _selectedImage == null) {
      throw Exception("No authenticated user found or image not selected");
    }

    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('userProfilePhotos') // The directory name in Firebase Storage
        .child(currentUser.uid) // The user's UID
        .child('${currentUser.uid}.jpg'); // The image file name

    final UploadTask uploadTask = storageRef.putFile(_selectedImage!);

    final TaskSnapshot uploadSnapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await uploadSnapshot.ref.getDownloadURL();

    setState(() {
      _isUploading = false;
    });

    return downloadUrl;
  }


  Future<void> _saveProfileChanges() async {
    // Validation
    if (!_usernameValidator.hasMatch(_usernameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username must contain only lowercase letters and numbers")),
      );
      return;
    }

    if (_bioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bio cannot be empty")),
      );
      return;
    }

    if (_birthdateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Birthdate cannot be empty")),
      );
      return;
    }

    try {
      final DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.userId);

      String photoUrl = _photoUrl ?? '';

      if (_selectedImage != null) {
        photoUrl = await _uploadUserProfilePhoto();
      }

      Map<String, dynamic> userProfileData = {
        'photoUrl': photoUrl,
        'username': _usernameController.text,
        'email': _emailController.text,
        // Format the _selectedDate for Firestore
        'birthdate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'bio' : _bioController.text,
      };

      await userRef.set(userProfileData);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile successfully updated")),
      );

      // Navigate to UserProfileViewPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBarPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        automaticallyImplyLeading: false, // Set this to false to hide the back button
        leading: IconButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white,),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white,),
            onPressed: () {
              _logout(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget> [
            SizedBox(height: 40.0),
            GestureDetector(
              onTap: _selectImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200.0,
                    height: 200.0,
                    child: (_selectedImage == null && (_photoUrl == null || _photoUrl!.isEmpty))
                        ? Material(
                      child: Image.asset(
                        'lib/assets/img/user.jpeg',
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(40.0)),
                      clipBehavior: Clip.hardEdge,
                    )
                        : Material(
                      child: _selectedImage != null
                          ? Image.file(
                        _selectedImage!,
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      )
                          : CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(pShadeColor6),
                          ),
                          width: 200.0,
                          height: 200.0,
                          padding: EdgeInsets.all(20),
                        ),
                        imageUrl: _photoUrl!,
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(40.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                  ),
                  if (_isUploading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(pShadeColor6),
                    ),
                ],
              ),
            ),
            SizedBox(height: 55.0),

            if (_isEditingUsername)
              Container(
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                child: Theme(
                  data: Theme.of(context).copyWith(primaryColor: pShadeColor4),
                  child: TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: pShadeColor9),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: pShadeColor8),
                      hintText: "Enter your username",
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: pShadeColor6, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: pShadeColor5, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      errorText: _usernameValidator.hasMatch(_usernameController.text)
                          ? null
                          : 'Username can only contain lowercase letters and numbers',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.check, color: pShadeColor6),
                        onPressed: () {
                          setState(() {
                            _isEditingUsername = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingUsername = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: pShadeColor6, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _usernameController.text.isEmpty ? "Enter your username" : _usernameController.text,
                          style: TextStyle(fontSize: 18.0, color: pShadeColor9),
                        ),
                      ),
                      Icon(Icons.edit, color: pShadeColor6),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20.0),

            // Email display section
            Container(
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                border: Border.all(color: pShadeColor6, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(fontSize: 18.0, color: pShadeColor9),
                    ),
                  ),
                  Icon(Icons.email, color: pShadeColor6),
                ],
              ),
            ),

            SizedBox(height: 20.0),

            // Birthdate selection section
            GestureDetector(
              onTap: () => _selectDate(context), // Directly call _selectDate
              child: Container(
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: pShadeColor6, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthdateController.text.isEmpty
                            ? "Select your birthdate"
                            : _birthdateController.text,
                        style: TextStyle(fontSize: 18.0, color: pShadeColor9),
                      ),
                    ),
                    Icon(Icons.calendar_today, color: pShadeColor6),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.0),

            if (_isEditingBio)
              Container(
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                child: Theme(
                  data: Theme.of(context).copyWith(primaryColor: pShadeColor4),
                  child: TextFormField(
                    controller: _bioController,
                    style: TextStyle(color: pShadeColor9),
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(color: pShadeColor8),
                      hintText: "Enter your bio",
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: pShadeColor6, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: pShadeColor5, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.check, color: pShadeColor6),
                        onPressed: () {
                          setState(() {
                            _isEditingBio = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingBio = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: pShadeColor6, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _bioController.text.isEmpty ? "Enter your bio" : _bioController.text,
                          style: TextStyle(fontSize: 18.0, color: pShadeColor9),
                        ),
                      ),
                      Icon(Icons.edit, color: pShadeColor6),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 36),

            //update profile button
            Container(
              child: ElevatedButton(
                onPressed: _saveProfileChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pShadeColor4, // Background color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 135.0), // Padding
                ),
                child: Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 20,),

            // Delete account button in your widget tree
            Container(
              child: ElevatedButton(
                onPressed: _showDeleteConfirmationDialog,  // Call the dialog function here
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Background color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 125.0), // Padding
                ),
                child: Text(
                  "Delete Account",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

