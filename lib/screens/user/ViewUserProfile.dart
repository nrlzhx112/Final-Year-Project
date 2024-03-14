import 'package:emindmatterssystem/screens/user/EditUserProfile.dart';
import 'package:emindmatterssystem/screens/user/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emindmatterssystem/utils/constant.dart'; // Assuming this contains your color and style constants

class ViewUserProfile extends StatefulWidget {
  @override
  _ViewUserProfileState createState() => _ViewUserProfileState();
}

class _ViewUserProfileState extends State<ViewUserProfile> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Update the user's online status in Firestore
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'isOnline': false});
      }

      // Sign out from Firebase Auth
      await auth.FirebaseAuth.instance.signOut();

      // Navigate to the welcome screen
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    } catch (e) {
      print('Logout failed: $e');
      // Optionally, handle the error more gracefully
    }
  }

  Future<void> _fetchProfileData() async {
    final DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();

    if (profileSnapshot.exists) {
      setState(() {
        userProfileData = profileSnapshot.data() as Map<String, dynamic>?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        automaticallyImplyLeading: false, // Set this to false to hide the back button
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
      body: userProfileData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: 40.0),
            _profileImage(),
            SizedBox(height: 20.0),
            _profileInfo('Username', userProfileData?['username']),
            _profileInfo('Email', userProfileData?['email']),
            _profileInfo('Birthdate', userProfileData?['birthdate']),
            _profileInfo('Bio', userProfileData?['bio']),
            _editProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _profileImage() {
    String? photoUrl = userProfileData?['photoUrl'];
    return Container(
      width: 200.0,
      height: 200.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: photoUrl != null && photoUrl.isNotEmpty
              ? CachedNetworkImageProvider(photoUrl)
              : AssetImage('lib/assets/img/user.jpeg') as ImageProvider,
        ),
      ),
    );
  }

  Widget _profileInfo(String title, String? value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: pShadeColor9,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(
                color: pShadeColor8,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editProfileButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          if (userProfileData != null) {
            DateTime? birthdate;
            if (userProfileData?['birthdate'] != null) {
              birthdate = DateTime.tryParse(userProfileData!['birthdate']);
            }

            // Create a UserModel instance
            UserModel userModel = UserModel(
              userId: currentUser!.uid,
              email: userProfileData!['email'],
              username: userProfileData!['username'],
              birthdate: birthdate,
              bio: userProfileData?['bio'],
              photoUrl: userProfileData?['photoUrl'],
              isOnline: true,
              role: UserRole.user,
            );

            // Navigate to EditUserProfile with the UserModel instance
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditUserProfile(user: userModel)),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: pShadeColor4,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 135.0),
        ),
        child: Text(
          "Edit Profile",
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
