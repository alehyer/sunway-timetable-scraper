import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/refresh_signal.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() =>
      _UpdateProfilePageState();
}

class _UpdateProfilePageState
    extends State<UpdateProfilePage> {
  final TextEditingController
  studentIdController = TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;

  bool hidePassword = true;

  String? loggedInId;

  static const int sessionDays = 7;

  @override
  void initState() {
    super.initState();

    loadLoginStatus();
  }

  Future<void> loadLoginStatus() async {
    final prefs =
        await SharedPreferences.getInstance();

    final id = prefs.getString('studentId');

    final timestamp = prefs.getInt(
      'loginTimestamp',
    );

    if (id == null || timestamp == null) {
      return;
    }

    final loginDate =
        DateTime.fromMillisecondsSinceEpoch(
          timestamp,
        );

    if (DateTime.now()
            .difference(loginDate)
            .inDays >=
        sessionDays) {
      await prefs.remove('studentId');

      await prefs.remove('loginTimestamp');

      return;
    }

    setState(() {
      loggedInId = id;
    });
  }

  Future<void> login() async {
    final id = studentIdController.text.trim();

    final password = passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      showMessage(
        "Enter Student ID and Password",
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://10.0.2.2:8020/api/timetable/scrape',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          "studentId": id,

          "password": password,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        showMessage(
          "Invalid Student ID or Password",
        );

        return;
      }

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString('studentId', id);

      await prefs.setInt(
        'loginTimestamp',

        DateTime.now().millisecondsSinceEpoch,
      );

      await prefs.setString(
        'timetableData',
        response.body,
      );

      timetableRefreshSignal.value++;

      setState(() {
        loggedInId = id;
      });

      passwordController.clear();

      showMessage(
        "Timetable updated successfully",
      );
    } catch (e) {
      showMessage("Connection error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    studentIdController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Image.asset(
                    'assets/sunwaylogo.png',

                    height: 80,
                  ),

                  const SizedBox(height: 20),

                  if (loggedInId != null)
                    Text(
                      "Logged in as $loggedInId",

                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      "Login to load timetable",
                    ),

                  const SizedBox(height: 20),

                  TextField(
                    controller:
                        studentIdController,

                    decoration:
                        const InputDecoration(
                          labelText: "Student ID",

                          border:
                              OutlineInputBorder(),
                        ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller:
                        passwordController,

                    obscureText: hidePassword,

                    decoration: InputDecoration(
                      labelText: "Password",

                      border:
                          const OutlineInputBorder(),

                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons
                                    .visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            hidePassword =
                                !hidePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,

                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : login,

                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
