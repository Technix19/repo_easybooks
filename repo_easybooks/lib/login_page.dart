import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repo_easybooks/signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscureLoginPassword = true;
  String email = "";
  //String password = "";

  void logIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
        emailRedirectTo: '${Uri.base.origin}/#/',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.lightGreenAccent,
          content: Text(
            "We’ve just emailed you a magic link — check your inbox to sign in!",
          ),
        ),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "An error occurred: $e",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF161616)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Welcome to EasyBooks!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 80,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  Center(
                    child: Lottie.asset(
                      "assets/lotties/analytics.json",
                      width: 500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 500,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 50.0, top: 130, right: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EasyBooks",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),

                    SizedBox(height: 80),

                    Text(
                      "Login into your account!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [
                        Text("Don't have an account? "),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return SignUpPage();
                                },
                              ),
                            );
                          },
                          child: Text(
                            " Sign up",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 40),

                    TextField(
                      decoration: InputDecoration(label: Text("Email")),
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                    ),

                    SizedBox(height: 40),

                    Center(
                      child: InkWell(
                        onTap: logIn,
                        child: Container(
                          width: 200,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Color(0xFF6FFF43),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text(
                              "Log in",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
