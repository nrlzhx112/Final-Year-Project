import 'package:emindmatterssystem/screens/auth/ForgotPasswordPage.dart';
import 'package:emindmatterssystem/screens/auth/RegisterPage.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/constant.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEmailValid = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPasswordVisible = false;

  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = EmailValidator.validate(email);
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _loginUser(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Access the authenticated user from userCredential.user
      User? user = userCredential.user;

      // You can now use the user information as needed
      print('User ID: ${user?.uid}');
      print('User Email: ${user?.email}');

      // Login successful, navigate to home screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBarPage()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Login failed. Please check your email and password.',
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  //memory control
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                      padding: const EdgeInsets.only(top: 120.0),
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
                            children: [
                              TextSpan(
                                text: "Welcome",
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

                    const SizedBox(height: 50),

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
                          hintText: "Email",
                          prefixIcon: Icon(Icons.email),
                          errorText: _isEmailValid ? null : 'Invalid email format',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) => _validateEmail(value),
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
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
                            borderSide:  BorderSide(color: pShadeColor6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Password",
                          prefixIcon: Icon(Icons.lock),
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
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding (
                      padding: const EdgeInsets.symmetric(horizontal:25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) {
                                      return ForgotPasswordPage();
                                    },
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: pShadeColor7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    //Login button.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: GestureDetector(
                        onTap: () => _loginUser(context),
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
                                onTap: () => _loginUser(context),
                                child: Center(
                                  child: Text(
                                    "Login",
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
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()), // Replace LoginPage with your actual login page widget.
                            );
                          },
                          child: Text(
                            " Register",
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
