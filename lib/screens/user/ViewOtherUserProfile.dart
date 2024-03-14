import 'package:emindmatterssystem/screens/home/SearchPage.dart';
import 'package:emindmatterssystem/screens/user/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emindmatterssystem/utils/constant.dart';

class ViewOtherUserProfile extends StatefulWidget {
  final UserModel? userModel; // Accept UserModel instance
  final String? userId;

  // Update the constructor to accept UserModel or userId
  ViewOtherUserProfile({this.userModel, this.userId});

  @override
  _ViewOtherUserProfileState createState() => _ViewOtherUserProfileState();
}


class _ViewOtherUserProfileState extends State<ViewOtherUserProfile> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfileData;

  @override
  void initState() {
    super.initState();
    if (widget.userModel != null) {
      _populateUserProfileData(widget.userModel!);
    } else if (widget.userId != null) {
      _fetchProfileData(widget.userId!);
    }
  }

  Future<void> _populateUserProfileData(UserModel userModel) async {
    setState(() {
      userProfileData = userModel.toJson();
    });
  }

  Future<void> _fetchProfileData(String userId) async {
    final DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
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
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          },
          icon: Icon(Icons.close, color: Colors.white,),
        ),
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
            _profileInfo('Bio', userProfileData?['bio']),
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
}
