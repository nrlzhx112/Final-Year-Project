import 'package:emindmatterssystem/screens/user/UserModel.dart';
import 'package:emindmatterssystem/screens/auth/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/constant.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  //text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); //letak dlm text field utk keep track
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEmailValid = true;
  bool _isUsernameValid = true;
  bool _isPasswordValid = true;
  bool _isPasswordMatched = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;


  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = EmailValidator.validate(email);
    });
  }

  void _validateUsername(String username) {
    RegExp regExp = RegExp(r'^[a-z0-9]+$'); // Regular expression for lowercase letters and numbers
    setState(() {
      _isUsernameValid = regExp.hasMatch(username);
    });
  }

  void _validatePassword(String password) {
    setState(() {
      _isPasswordValid = password.length >= 6;
    });
  }

  void _validateConfirmPassword(String confirmPassword) {
    String password = _passwordController.text;
    setState(() {
      _isPasswordMatched = password == confirmPassword;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _registerUser(BuildContext context) async {
    try {
      String email = _emailController.text;
      String password = _passwordController.text;
      String confirmPassword = _confirmPasswordController.text;
      String username = _usernameController.text;

      if (!_isEmailValid || !_isPasswordValid || !_isPasswordMatched || username.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please fix the validation errors.',
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      if (confirmPassword.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please confirm your password.',
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Handle any specific errors related to user registration.
        // add specific error messages or actions here.
        print(e.toString());
      }

      if (userCredential != null) {

        // Registration successful, create UserModel with user ID and default notification preferences
        UserModel userModel = UserModel(
          userId: userCredential.user!.uid,
          email: email,
          username: username,
          isOnline: true,
          role: UserRole.user,
        );

        // Define a Map for user profile data
        Map<String, dynamic> userProfileData = {
          'photoUrl': '',
          'username': username,
          'email': email,
          'birthdate': '',
          'bio': '',
        };

        try {
          await _firestore.collection('users').doc(userModel.userId).set({
            'email': userModel.email,
            'username': userModel.username,
            // Add more fields as needed
          });
          // Generate a unique document ID for the user profile data
          String profileDocId = _firestore.collection('users').doc(userModel.userId).collection('userProfile').doc().id;

          // Save the user profile data with the generated document ID
          await _firestore
              .collection('users')
              .doc(userModel.userId)
              .collection('userProfile')
              .doc(profileDocId)
              .set(userProfileData);

        } catch (e) {
          print('Error setting user data in Firestore: $e');
          Fluttertoast.showToast(
            msg: 'Error setting user data in Firestore: $e',
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }

        // Navigate to home screen or any other screen as desired
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: 'Registration successful.',
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Registration failed. Please try again later.',
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again later.',
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  //memory control
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity, //used to make the width of a widget expand to fill the available horizontal space
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/img/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Image.asset(
                        'lib/assets/img/logo1.png',
                        width: 200,
                        height: 200,
                      ),
                    ),
                    SizedBox(height: size.height * 0.001),
                    Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.titleLarge,
                            children:  [
                              TextSpan(
                                text: "Glad to have you",
                                style: TextStyle(
                                  fontSize: 35,
                                  color: pShadeColor9,
                                ),
                              ),
                              TextSpan(
                                text: " back!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 35,
                                  color: pShadeColor8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "We are here to help you be better ",
                          style: TextStyle(
                            fontSize: 18,
                            color: pShadeColor7,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    //Username textfield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              style: BorderStyle.none,
                              color: Colors.white,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: pShadeColor6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter your username",
                          prefixIcon: Icon(Icons.person),
                          errorText: _isUsernameValid ? null : 'Username can only contain lowercase letters and numbers',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) => _validateUsername(value),
                      ),
                    ),

                    const SizedBox(height: 10),

                    //Email textfield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              style: BorderStyle.none,
                              color: Colors.white,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: pShadeColor6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter your email",
                          prefixIcon: Icon(Icons.email),
                          errorText: _isEmailValid ? null : 'Invalid email format',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => _validateEmail(value),
                      ),
                    ),

                    const SizedBox(height: 10),

                    //password textfield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              style: BorderStyle.none,
                              color: Colors.white,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: pShadeColor6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter your password",
                          prefixIcon: Icon(Icons.lock),
                          errorText: _isPasswordValid ? null : 'Password should be at least 6 characters',
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon: GestureDetector(
                            onTap: _togglePasswordVisibility,
                            child: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        onChanged: (value) => _validatePassword(value),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // confirm password textfield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              style: BorderStyle.none,
                              color: Colors.white,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: pShadeColor6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Re-enter your password",
                          prefixIcon: Icon(Icons.lock),
                          errorText: _isPasswordMatched ? null : 'Passwords do not match',
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon: GestureDetector(
                            onTap: _toggleConfirmPasswordVisibility,
                            child: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        obscureText: !_isConfirmPasswordVisible,
                        onChanged: (value) => _validateConfirmPassword(value),
                      ),
                    ),

                    const SizedBox(height: 30),

                    //Register button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: GestureDetector(
                        onTap: () => _registerUser(context),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: pShadeColor5,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pShadeColor6), // Set border color to pUIColor3
                          ),
                          child: Center(
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.white, // Set hover background color to white
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _registerUser(context),
                                child: Center(
                                  child: Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.white, // Set hover text color to pUIColor2
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Don't have an account? Signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()), // Replace LoginPage with your actual login page widget.
                            );
                          },
                          child: Text(
                            " Login",
                            style: TextStyle(
                              color: pShadeColor7,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


